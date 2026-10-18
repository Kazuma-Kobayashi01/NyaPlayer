"""Apollo split around its STFT, so the network itself can run in FP16.

`torch.stft` / `istft` stay in FP32 (complex FP16 is not supported on the GPU,
and the STFT is cheap); only the 80-band network in between is converted.
"""
import torch
import torch.nn as nn


class ApolloCore(nn.Module):
    """Apollo minus torch.stft / torch.istft: spectrum in, spectrum out.

    Takes the real and imaginary parts as separate real tensors [N, 442, T]
    (N = batch x channels) and returns the estimated ones, using the model's
    own submodules so the weights are the same.
    """

    def __init__(self, m):
        super().__init__()
        self.m = m

    def forward(self, re, im):
        m = self.m
        feats = []
        idx = 0
        for i in range(m.nband):
            bw = m.band_width[i]
            r, q = re[:, idx : idx + bw], im[:, idx : idx + bw]
            power = (r.pow(2) + q.pow(2)).sum(1, keepdim=True).add(m.eps).sqrt()
            feats.append(m.BN[i](torch.cat([r / power, q / power, torch.log(power)], 1)))
            idx += bw
        feature = m.net(torch.stack(feats, 1))
        est_re, est_im = [], []
        for i in range(m.nband):
            ri = m.output[i](feature[:, i]).view(re.shape[0], 2, m.band_width[i], -1)
            est_re.append(ri[:, 0])
            est_im.append(ri[:, 1])
        return torch.cat(est_re, 1), torch.cat(est_im, 1)


class MixedPrecisionApollo(nn.Module):
    """Same interface as Apollo ([B, ch, samples] in and out, FP32 at the
    edges), network in `dtype`."""

    def __init__(self, model, dtype=torch.float16):
        super().__init__()
        self.win, self.stride, self.dtype = model.win, model.stride, dtype
        self.core = ApolloCore(model).to(dtype)

    def forward(self, audio):
        b, nch, n = audio.shape
        window = torch.hann_window(self.win, device=audio.device)
        spec = torch.stft(
            audio.reshape(b * nch, n), n_fft=self.win, hop_length=self.stride,
            window=window, return_complex=True,
        )
        re, im = self.core(spec.real.to(self.dtype), spec.imag.to(self.dtype))
        est = torch.complex(re.float(), im.float())
        out = torch.istft(est, n_fft=self.win, hop_length=self.stride, window=window, length=n)
        return out.reshape(b, nch, -1)
