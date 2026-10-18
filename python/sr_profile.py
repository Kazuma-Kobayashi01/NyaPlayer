"""Where does Apollo spend its time on the GPU? One 7 s window, per stage."""
import sys
import time
from pathlib import Path

import torch

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "vendor" / "Apollo"))
import look2hear.models  # noqa: E402

SR = 44100
dev = "mps"
m = look2hear.models.BaseModel.from_pretrain(
    str(HERE / "models" / "pytorch_model.bin"), sr=SR, win=20, feature_dim=256, layer=6
).eval().to(dev)

n = int(7 * SR)
audio = (torch.randn(2, n) * 0.1).to(dev)
window = torch.hann_window(m.win, device=dev)
spec = torch.stft(audio, n_fft=m.win, hop_length=m.stride, window=window, return_complex=True)
re, im = spec.real.contiguous(), spec.imag.contiguous()
print("spectrum", tuple(re.shape))


def sync():
    torch.mps.synchronize()


def timed(fn, repeat=3):
    fn(); sync()  # warm up
    t = time.perf_counter()
    for _ in range(repeat):
        out = fn()
    sync()
    return (time.perf_counter() - t) / repeat * 1000, out


def input_stage():
    feats, idx = [], 0
    for i in range(m.nband):
        bw = m.band_width[i]
        r, q = re[:, idx : idx + bw], im[:, idx : idx + bw]
        power = (r.pow(2) + q.pow(2)).sum(1, keepdim=True).add(m.eps).sqrt()
        feats.append(m.BN[i](torch.cat([r / power, q / power, torch.log(power)], 1)))
        idx += bw
    return torch.stack(feats, 1)


with torch.inference_mode():
    t_in, feat = timed(input_stage)
    print(f"input stage (80-band loop)   {t_in:8.1f} ms   feature {tuple(feat.shape)}")
    total_layers = 0.0
    x = feat
    for li, layer in enumerate(m.net):
        B, nband, N, T = x.shape

        def band_part(x=x):
            bi = x.permute(0, 3, 2, 1).reshape(B * T, -1, nband)
            bo, _ = layer.band_net(bi)
            return bo.reshape(B, T, -1, nband).permute(0, 3, 2, 1)

        tb, bo = timed(band_part)

        def seq_part(bo=bo):
            return layer.seq_net(bo.reshape(B * nband, -1, T)).reshape(B, nband, -1, T)

        ts, x = timed(seq_part)
        total_layers += tb + ts
        print(f"layer {li}: band attention {tb:7.1f} ms, time convs {ts:7.1f} ms")
    print(f"6 layers total               {total_layers:8.1f} ms")

    def output_stage(feature=x):
        est_re, est_im = [], []
        for i in range(m.nband):
            ri = m.output[i](feature[:, i]).view(re.shape[0], 2, m.band_width[i], -1)
            est_re.append(ri[:, 0]); est_im.append(ri[:, 1])
        return torch.cat(est_re, 1), torch.cat(est_im, 1)

    t_out, _ = timed(output_stage)
    print(f"output stage (80-band loop)  {t_out:8.1f} ms")
    total = t_in + total_layers + t_out
    print(f"sum {total:.0f} ms  =  input {100 * t_in / total:.0f}%, layers {100 * total_layers / total:.0f}%, output {100 * t_out / total:.0f}%")
    print(f"(7 s of audio, so x{7000 / total:.2f} realtime without STFT/iSTFT)")
