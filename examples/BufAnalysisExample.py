from mmm_python import *
import matplotlib.pyplot as plt

d = {"path":"resources/Shiverer.wav"}
a = MBufAnalysis.rms(d)
print(a[0][0].dtype)

plt.plot(a)
plt.title("RMS Analysis")
plt.xlabel("Frame")
plt.ylabel("RMS")
plt.show()