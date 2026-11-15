import sys, sherpa_onnx, soundfile as sf
M='/home/claude/tts/model/vits-piper-vi_VN-vais1000-medium/'
cfg=sherpa_onnx.OfflineTtsConfig(model=sherpa_onnx.OfflineTtsModelConfig(vits=sherpa_onnx.OfflineTtsVitsModelConfig(
  model=M+'vi_VN-vais1000-medium.onnx',tokens=M+'tokens.txt',data_dir=M+'espeak-ng-data',length_scale=float(sys.argv[3]) if len(sys.argv)>3 else 1.0,noise_scale=0.6),num_threads=2))
tts=sherpa_onnx.OfflineTts(cfg); a=tts.generate(sys.argv[1],sid=0,speed=1.0)
sf.write(sys.argv[2],a.samples,a.sample_rate); print(sys.argv[2],a.sample_rate,len(a.samples)/a.sample_rate)
