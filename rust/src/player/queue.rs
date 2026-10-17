//! Pure play-queue model used by the engine thread.
//!
//! Mirrors the semantics of the Dart `PlayerEngine` contract (and of
//! `FakePlayerEngine`): the Dart `QueueController` is the source of truth and
//! sends incremental edits; this model keeps the engine's copy in sync and
//! decides which item plays next. Every item carries a stable id so the
//! engine can tell whether a prefetched source is still the right "next"
//! after the list was edited.

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum LoopMode {
    None,
    All,
    One,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Item {
    pub id: u64,
    pub path: String,
}

/// What a removal did to the current item.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RemoveEffect {
    /// The current item is unchanged (its index may have shifted).
    CurrentKept,
    /// The current item was removed; the new current item (if any) must be
    /// started from the beginning.
    CurrentRemoved,
}

#[derive(Debug)]
pub struct PlayQueue {
    items: Vec<Item>,
    current: Option<usize>,
    pub loop_mode: LoopMode,
    next_id: u64,
}

impl Default for PlayQueue {
    fn default() -> Self {
        Self::new()
    }
}

impl PlayQueue {
    pub fn new() -> Self {
        Self {
            items: Vec::new(),
            current: None,
            loop_mode: LoopMode::None,
            next_id: 1,
        }
    }

    fn make_item(&mut self, path: String) -> Item {
        let id = self.next_id;
        self.next_id += 1;
        Item { id, path }
    }

    pub fn len(&self) -> usize {
        self.items.len()
    }

    pub fn is_empty(&self) -> bool {
        self.items.is_empty()
    }

    pub fn current(&self) -> Option<usize> {
        self.current
    }

    pub fn item(&self, index: usize) -> Option<&Item> {
        self.items.get(index)
    }

    pub fn index_of(&self, id: u64) -> Option<usize> {
        self.items.iter().position(|item| item.id == id)
    }

    /// Replaces the whole list. The current index is clamped into range.
    pub fn set(&mut self, paths: Vec<String>, start: usize) {
        self.items = paths.into_iter().map(|p| self.make_item(p)).collect();
        self.current = if self.items.is_empty() {
            None
        } else {
            Some(start.min(self.items.len() - 1))
        };
    }

    pub fn set_current(&mut self, index: Option<usize>) {
        self.current = index.filter(|&i| i < self.items.len());
    }

    /// Index that follows `index` under the current loop mode.
    pub fn next_after(&self, index: usize) -> Option<usize> {
        if index >= self.items.len() {
            return None;
        }
        match self.loop_mode {
            LoopMode::One => Some(index),
            _ if index + 1 < self.items.len() => Some(index + 1),
            LoopMode::All => Some(0),
            LoopMode::None => None,
        }
    }

    /// Item that should play after the current one.
    pub fn next_index(&self) -> Option<usize> {
        self.current.and_then(|c| self.next_after(c))
    }

    /// Appends an item. An empty queue gets a current item (not started).
    /// Returns true when the current index changed.
    pub fn add(&mut self, path: String) -> bool {
        let item = self.make_item(path);
        self.items.push(item);
        if self.current.is_none() {
            self.current = Some(0);
            return true;
        }
        false
    }

    /// Inserts at `index` (clamped). Returns true when the current index
    /// changed (shifted, or set because the queue was empty).
    pub fn insert(&mut self, index: usize, path: String) -> bool {
        let at = index.min(self.items.len());
        let item = self.make_item(path);
        self.items.insert(at, item);
        match self.current {
            None => {
                self.current = Some(0);
                true
            }
            Some(c) if at <= c => {
                self.current = Some(c + 1);
                true
            }
            Some(_) => false,
        }
    }

    /// Removes the item at `index`. Out-of-range indexes are ignored.
    pub fn remove(&mut self, index: usize) -> RemoveEffect {
        if index >= self.items.len() {
            return RemoveEffect::CurrentKept;
        }
        self.items.remove(index);
        let Some(c) = self.current else {
            return RemoveEffect::CurrentKept;
        };
        if self.items.is_empty() {
            self.current = None;
            return RemoveEffect::CurrentRemoved;
        }
        if index < c {
            self.current = Some(c - 1);
            RemoveEffect::CurrentKept
        } else if index == c {
            // The next item takes its place; at the end, the previous one.
            self.current = Some(c.min(self.items.len() - 1));
            RemoveEffect::CurrentRemoved
        } else {
            RemoveEffect::CurrentKept
        }
    }

    /// Moves an item so that it ends up at `to` in the resulting list.
    /// Returns true when the current index changed.
    pub fn move_item(&mut self, from: usize, to: usize) -> bool {
        if from == to || from >= self.items.len() {
            return false;
        }
        let item = self.items.remove(from);
        let to = to.min(self.items.len());
        self.items.insert(to, item);
        let Some(c) = self.current else {
            return false;
        };
        let next = if c == from {
            to
        } else if from < c && to >= c {
            c - 1
        } else if from > c && to <= c {
            c + 1
        } else {
            c
        };
        self.current = Some(next);
        next != c
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn paths(names: &[&str]) -> Vec<String> {
        names.iter().map(|s| s.to_string()).collect()
    }

    fn names(q: &PlayQueue) -> Vec<String> {
        (0..q.len())
            .map(|i| q.item(i).unwrap().path.clone())
            .collect()
    }

    #[test]
    fn set_clamps_start() {
        let mut q = PlayQueue::new();
        q.set(paths(&["a", "b"]), 5);
        assert_eq!(q.current(), Some(1));
        q.set(vec![], 0);
        assert_eq!(q.current(), None);
    }

    #[test]
    fn next_follows_loop_mode() {
        let mut q = PlayQueue::new();
        q.set(paths(&["a", "b", "c"]), 2);
        assert_eq!(q.next_index(), None);
        q.loop_mode = LoopMode::All;
        assert_eq!(q.next_index(), Some(0));
        q.loop_mode = LoopMode::One;
        assert_eq!(q.next_index(), Some(2));
        q.set_current(Some(0));
        q.loop_mode = LoopMode::None;
        assert_eq!(q.next_index(), Some(1));
    }

    #[test]
    fn add_to_empty_sets_current() {
        let mut q = PlayQueue::new();
        assert!(q.add("a".into()));
        assert_eq!(q.current(), Some(0));
        assert!(!q.add("b".into()));
    }

    #[test]
    fn insert_before_current_shifts_it() {
        let mut q = PlayQueue::new();
        q.set(paths(&["a", "b", "c"]), 1);
        assert!(q.insert(0, "x".into()));
        assert_eq!(q.current(), Some(2));
        assert!(!q.insert(10, "y".into()));
        assert_eq!(names(&q), paths(&["x", "a", "b", "c", "y"]));
    }

    #[test]
    fn remove_rules() {
        let mut q = PlayQueue::new();
        q.set(paths(&["a", "b", "c", "d"]), 2);
        assert_eq!(q.remove(0), RemoveEffect::CurrentKept);
        assert_eq!(q.current(), Some(1)); // still "c"
        assert_eq!(q.remove(1), RemoveEffect::CurrentRemoved);
        assert_eq!(q.item(q.current().unwrap()).unwrap().path, "d");
        assert_eq!(q.remove(1), RemoveEffect::CurrentRemoved); // last → previous
        assert_eq!(q.item(q.current().unwrap()).unwrap().path, "b");
        assert_eq!(q.remove(0), RemoveEffect::CurrentRemoved);
        assert_eq!(q.current(), None);
        assert!(q.is_empty());
    }

    #[test]
    fn move_keeps_current_item() {
        let mut q = PlayQueue::new();
        q.set(paths(&["a", "b", "c", "d"]), 1); // current "b"
        q.move_item(0, 3); // b c d a
        assert_eq!(names(&q), paths(&["b", "c", "d", "a"]));
        assert_eq!(q.current(), Some(0));
        q.move_item(0, 2); // c d b a
        assert_eq!(q.current(), Some(2));
        q.move_item(3, 0); // a c d b
        assert_eq!(names(&q), paths(&["a", "c", "d", "b"]));
        assert_eq!(q.current(), Some(3));
    }

    #[test]
    fn ids_are_stable_across_edits() {
        let mut q = PlayQueue::new();
        q.set(paths(&["a", "b"]), 0);
        let id_b = q.item(1).unwrap().id;
        q.insert(0, "x".into());
        assert_eq!(q.index_of(id_b), Some(2));
        q.remove(2);
        assert_eq!(q.index_of(id_b), None);
    }
}
