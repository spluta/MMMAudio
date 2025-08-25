# """
# This outputs something, but it isn't right!

# A translation of Miller Puckette's Mayer FFT implementation from Sigmund, etc.

# In respect of the author's wishes, we thank Euler, Gauss, Hartley, Buneman, Mayer, and Puckette.

# This should probably get replaced by an FFTW or RustFFT interface.
# """
# from python import PythonObject
# from python.bindings import PythonModuleBuilder

# from math import sqrt
# from memory import memset_zero
# from algorithm import vectorize

# from sys import simdwidthof

# # Constants
# alias SQRT2_2: Float64 = 0.70710678118654752440084436210484
# alias SQRT2: Float64 = 2 * 0.70710678118654752440084436210484

# # Pre-computed lookup tables
# alias halsec = List[Float64](
#     0.0,
#     0.0,
#     0.54119610014619698439972320536638942006107206337801,
#     0.50979557910415916894193980398784391368261849190893,
#     0.50241928618815570551167011928012092247859337193963,
#     0.50060299823519630134550410676638239611758632599591,
#     0.50015063602065098821477101271097658495974913010340,
#     0.50003765191554772296778139077905492847503165398345,
#     0.50000941253588775676512870469186533538523133757983,
#     0.50000235310628608051401267171204408939326297376426,
#     0.50000058827484117879868526730916804925780637276181,
#     0.50000014706860214875463798283871198206179118093251,
#     0.50000003676714377807315864400643020315103490883972,
#     0.50000000919178552207366560348853455333939112569380,
#     0.50000000229794635411562887767906868558991922348920,
#     0.50000000057448658687873302235147272458812263401372
# )

# alias costab = List[Float64](
#     0.00000000000000000000000000000000000000000000000000,
#     0.70710678118654752440084436210484903928483593768847,
#     0.92387953251128675612818318939678828682241662586364,
#     0.98078528040323044912618223613423903697393373089333,
#     0.99518472667219688624483695310947992157547486872985,
#     0.99879545620517239271477160475910069444320361470461,
#     0.99969881869620422011576564966617219685006108125772,
#     0.99992470183914454092164649119638322435060646880221,
#     0.99998117528260114265699043772856771617391725094433,
#     0.99999529380957617151158012570011989955298763362218,
#     0.99999882345170190992902571017152601904826792288976,
#     0.99999970586288221916022821773876567711626389934930,
#     0.99999992646571785114473148070738785694820115568892,
#     0.99999998161642929380834691540290971450507605124278,
#     0.99999999540410731289097193313960614895889430318945,
#     0.99999999885102682756267330779455410840053741619428
# )

# alias sintab = List[Float64](
#     1.0000000000000000000000000000000000000000000000000,
#     0.70710678118654752440084436210484903928483593768846,
#     0.38268343236508977172845998403039886676134456248561,
#     0.19509032201612826784828486847702224092769161775195,
#     0.09801714032956060199419556388864184586113667316749,
#     0.04906767432741801425495497694268265831474536302574,
#     0.02454122852291228803173452945928292506546611923944,
#     0.01227153828571992607940826195100321214037231959176,
#     0.00613588464915447535964023459037258091705788631738,
#     0.00306795676296597627014536549091984251894461021344,
#     0.00153398018628476561230369715026407907995486457522,
#     0.00076699031874270452693856835794857664314091945205,
#     0.00038349518757139558907246168118138126339502603495,
#     0.00019174759731070330743990956198900093346887403385,
#     0.00009587379909597734587051721097647635118706561284,
#     0.00004793689960306688454900399049465887274686668768
# )

# struct MMM_FFT(Movable, Representable):
#     var coswrk: List[Float64]
#     var sinwrk: List[Float64]

#     @staticmethod
#     fn py_init(out self: MMM_FFT, args: PythonObject, kwargs: PythonObject) raises:
#         """Initialize the MMM_FFT structure for Python."""
#         self = Self()

#     fn __init__(out self):
#         """Initialize the MMM_FFT structure with pre-computed cosine and sine tables."""
#         self.coswrk = List[Float64](
#             0.00000000000000000000000000000000000000000000000000,
#             0.70710678118654752440084436210484903928483593768847,
#             0.92387953251128675612818318939678828682241662586364,
#             0.98078528040323044912618223613423903697393373089333,
#             0.99518472667219688624483695310947992157547486872985,
#             0.99879545620517239271477160475910069444320361470461,
#             0.99969881869620422011576564966617219685006108125772,
#             0.99992470183914454092164649119638322435060646880221,
#             0.99998117528260114265699043772856771617391725094433,
#             0.99999529380957617151158012570011989955298763362218,
#             0.99999882345170190992902571017152601904826792288976,
#             0.99999970586288221916022821773876567711626389934930,
#             0.99999992646571785114473148070738785694820115568892,
#             0.99999998161642929380834691540290971450507605124278,
#             0.99999999540410731289097193313960614895889430318945,
#             0.99999999885102682756267330779455410840053741619428
#         )
#         self.sinwrk = List[Float64](
#             1.0000000000000000000000000000000000000000000000000,
#             0.70710678118654752440084436210484903928483593768846,
#             0.38268343236508977172845998403039886676134456248561,
#             0.19509032201612826784828486847702224092769161775195,
#             0.09801714032956060199419556388864184586113667316749,
#             0.04906767432741801425495497694268265831474536302574,
#             0.02454122852291228803173452945928292506546611923944,
#             0.01227153828571992607940826195100321214037231959176,
#             0.00613588464915447535964023459037258091705788631738,
#             0.00306795676296597627014536549091984251894461021344,
#             0.00153398018628476561230369715026407907995486457522,
#             0.00076699031874270452693856835794857664314091945205,
#             0.00038349518757139558907246168118138126339502603495,
#             0.00019174759731070330743990956198900093346887403385,
#             0.00009587379909597734587051721097647635118706561284,
#             0.00004793689960306688454900399049465887274686668768
#         )

#     fn __repr__(self) -> String:
#         return "MMM_FFT"

#     fn fht(mut self, mut fz: UnsafePointer[Float64], n: Int):
#         """Fast Hartley Transform implementation."""
#         var k: Int
#         var k1: Int = 1
#         var k2: Int = 0
#         var k3: Int
#         var k4: Int
#         var kx: Int
#         var t_lam: Int = 0
        
#         # Bit reversal
#         while k1 < n:
#             var aa: Float64
#             k = n >> 1
#             while (k2 ^ k) & k == 0:
#                 k2 ^= k
#                 k >>= 1
#             if k1 > k2:
#                 aa = fz[k1]
#                 fz[k1] = fz[k2]
#                 fz[k2] = aa
#             k1 += 1
        
#         # Find log2(n)
#         k = 0
#         var temp_n = n
#         while (1 << k) < temp_n:
#             k += 1
#         k &= 1
        
#         if k == 0:
#             # Length 4 DFTs
#             var fi = 0
#             while fi < n:
#                 var f0: Float64 = fz[fi] + fz[fi + 1]
#                 var f1: Float64 = fz[fi] - fz[fi + 1]
#                 var f2: Float64 = fz[fi + 2] + fz[fi + 3]
#                 var f3: Float64 = fz[fi + 2] - fz[fi + 3]
                
#                 fz[fi] = f0 + f2
#                 fz[fi + 2] = f0 - f2
#                 fz[fi + 1] = f1 + f3
#                 fz[fi + 3] = f1 - f3
#                 fi += 4
#         else:
#             # Length 8 DFTs
#             var fi = 0
#             while fi < n:
#                 var gi = fi + 1
                
#                 var bc1: Float64 = fz[fi] - fz[gi]
#                 var bs1: Float64 = fz[fi] + fz[gi]
#                 var bc2: Float64 = fz[fi + 2] - fz[gi + 2]
#                 var bs2: Float64 = fz[fi + 2] + fz[gi + 2]
#                 var bc3: Float64 = fz[fi + 4] - fz[gi + 4]
#                 var bs3: Float64 = fz[fi + 4] + fz[gi + 4]
#                 var bc4: Float64 = fz[fi + 6] - fz[gi + 6]
#                 var bs4: Float64 = fz[fi + 6] + fz[gi + 6]
                
#                 var bf0: Float64 = bs1 + bs2
#                 var bf1: Float64 = bs1 - bs2
#                 var bg0: Float64 = bc1 + bc2
#                 var bg1: Float64 = bc1 - bc2
#                 var bf2: Float64 = bs3 + bs4
#                 var bf3: Float64 = bs3 - bs4
#                 var bg2: Float64 = SQRT2 * bc3
#                 var bg3: Float64 = SQRT2 * bc4
                
#                 fz[fi] = bf0 + bf2
#                 fz[fi + 4] = bf0 - bf2
#                 fz[fi + 2] = bf1 + bf3
#                 fz[fi + 6] = bf1 - bf3
#                 fz[gi] = bg0 + bg2
#                 fz[gi + 4] = bg0 - bg2
#                 fz[gi + 2] = bg1 + bg3
#                 fz[gi + 6] = bg1 - bg3
#                 fi += 8
        
#         if n < 16:
#             return
        
#         # Main FFT loop
#         k += 2
#         while True:
#             k1 = 1 << k
#             k2 = k1 << 1
#             k4 = k2 << 1
#             k3 = k2 + k1
#             kx = k1 >> 1
            
#             # First pass without trig
#             var fi = 0
#             while fi < n:
#                 var gi = fi + kx
                
#                 var f0: Float64 = fz[fi] + fz[fi + k1]
#                 var f1: Float64 = fz[fi] - fz[fi + k1]
#                 var f2: Float64 = fz[fi + k2] + fz[fi + k3]
#                 var f3: Float64 = fz[fi + k2] - fz[fi + k3]
                
#                 fz[fi] = f0 + f2
#                 fz[fi + k2] = f0 - f2
#                 fz[fi + k1] = f1 + f3
#                 fz[fi + k3] = f1 - f3
                
#                 var g0: Float64 = fz[gi] + fz[gi + k1]
#                 var g1: Float64 = fz[gi] - fz[gi + k1]
#                 var g2: Float64 = SQRT2 * fz[gi + k2]
#                 var g3: Float64 = SQRT2 * fz[gi + k3]
                
#                 fz[gi] = g0 + g2
#                 fz[gi + k2] = g0 - g2
#                 fz[gi + k1] = g1 + g3
#                 fz[gi + k3] = g1 - g3
                
#                 fi += k4
            
#             # Remaining passes with trig
#             t_lam = 0
#             var c1: Float64 = 1.0
#             var s1: Float64 = 0.0
            
#             # Initialize trig values
#             for i in range(2, k + 1):
#                 self.coswrk[i] = costab[i]
#                 self.sinwrk[i] = sintab[i]

#             for ii in range(1, kx):
#                 # Compute next trig values
#                 t_lam += 1
#                 var i = 0
#                 while not ((1 << i) & t_lam):
#                     i += 1
#                 i = k - i
#                 s1 = self.sinwrk[i]
#                 c1 = self.coswrk[i]

#                 if i > 1:
#                     var j = k - i + 2
#                     while (1 << j) & t_lam:
#                         j += 1
#                     j = k - j
#                     self.sinwrk[i] = halsec[i] * (self.sinwrk[i-1] + self.sinwrk[j])
#                     self.coswrk[i] = halsec[i] * (self.coswrk[i-1] + self.coswrk[j])

#                 var c2: Float64 = c1 * c1 - s1 * s1
#                 var s2: Float64 = 2 * (c1 * s1)
                
#                 fi = ii
#                 while fi < n:
#                     var gi = k1 - ii + fi
                    
#                     var a: Float64 = c2 * fz[fi + k1] + s2 * fz[gi + k1 - ii]
#                     var b: Float64 = s2 * fz[fi + k1] - c2 * fz[gi + k1 - ii]
                    
#                     var f0: Float64 = fz[fi] + a
#                     var f1: Float64 = fz[fi] - a
#                     var g0: Float64 = fz[gi] + b
#                     var g1: Float64 = fz[gi] - b
                    
#                     a = c2 * fz[fi + k3] + s2 * fz[gi + k3 - ii]
#                     b = s2 * fz[fi + k3] - c2 * fz[gi + k3 - ii]
                    
#                     var f2: Float64 = fz[fi + k2] + a
#                     var f3: Float64 = fz[fi + k2] - a
#                     var g2: Float64 = fz[gi + k2 - ii] + b
#                     var g3: Float64 = fz[gi + k2 - ii] - b
                    
#                     a = c1 * f2 + s1 * g3
#                     b = s1 * f2 - c1 * g3
                    
#                     fz[fi] = f0 + a
#                     fz[fi + k2] = f0 - a
#                     fz[gi + k1 - ii] = g1 + b
#                     fz[gi + k3 - ii] = g1 - b
                    
#                     a = s1 * g2 + c1 * f3
#                     b = c1 * g2 - s1 * f3
                    
#                     fz[gi] = g0 + a
#                     fz[gi + k2 - ii] = g0 - a
#                     fz[fi + k1] = f1 + b
#                     fz[fi + k3] = f1 - b
                    
#                     fi += k4
            
#             if k4 >= n:
#                 break
#             k += 2

#     fn fft(mut self, n: Int, mut real: UnsafePointer[Float64], mut imag: UnsafePointer[Float64]):
#         """Fast Fourier Transform."""
#         var k = n // 2
#         for i in range(1, k):
#             var j = n - 1 - i
#             var a = real[i]
#             var b = real[j]
#             var c = imag[i]
#             var d = imag[j]
#             var q = a + b
#             var r = a - b
#             var s = c + d
#             var t = c - d
            
#             real[i] = (q + t) * 0.5
#             real[j] = (q - t) * 0.5
#             imag[i] = (s - r) * 0.5
#             imag[j] = (s + r) * 0.5
        
#         self.fht(real, n)
#         self.fht(imag, n)
    
#     fn fft(mut self, mut real: List[Float64], mut imag: List[Float64]):
#         """Inverse Real-valued Fast Fourier Transform."""
#         ptr: UnsafePointer[Float64] = UnsafePointer(to=real[0])
#         ptr_imag: UnsafePointer[Float64] = UnsafePointer(to=imag[0])

#         n = len(real)

#         self.fft(n, ptr, ptr_imag)

#     fn ifft(mut self, n: Int, mut real: UnsafePointer[Float64], mut imag: UnsafePointer[Float64]):
#         """Inverse Fast Fourier Transform."""
#         self.fht(real, n)
#         self.fht(imag, n)

#         var k = n // 2
#         for i in range(1, k):
#             var j = n - 1 - i
#             var a = real[i]
#             var b = real[j]
#             var c = imag[i]
#             var d = imag[j]
#             var q = a + b
#             var r = a - b
#             var s = c + d
#             var t = c - d
            
#             imag[i] = (s + r) * 0.5
#             imag[j] = (s - r) * 0.5
#             real[i] = (q - t) * 0.5
#             real[j] = (q + t) * 0.5

#     fn ifft(mut self, mut real: List[Float64], mut imag: List[Float64]):
#         """Inverse Real-valued Fast Fourier Transform."""
#         ptr: UnsafePointer[Float64] = UnsafePointer(to=real[0])
#         ptr_imag: UnsafePointer[Float64] = UnsafePointer(to=imag[0])

#         n = len(real)

#         self.ifft(n, ptr, ptr_imag)

#     fn rfft(mut self, n: Int, mut real: UnsafePointer[Float64]):
#         """Real-valued Fast Fourier Transform."""
#         print(n)

#         self.fht(real, n)

#         var k = n // 2
#         for i in range(1, k):
#             var j = n - 1 - i
#             var a = real[i]
#             var b = real[j]
#             real[j] = (a - b) * 0.5
#             real[i] = (a + b) * 0.5

#     fn rfft_s(mut self, n: Int, mut real: UnsafePointer[Float64]):
#         """Real-valued Fast Fourier Transform (single precision)."""
#         print(n)

#         self.fht(real, n)

#         var k = n // 2
#         alias simd_width = simdwidthof[Float64]()
    
#         @parameter
#         fn vectorized_transform[simd_width: Int](idx: Int):
#             var i = idx + 1  # Start from index 1
#             if i < k:
#                 var j = n - 1 - i
#                 var a = real[i]
#                 var b = real[j]
#                 real[j] = (a - b) * 0.5
#                 real[i] = (a + b) * 0.5
        
#         vectorize[vectorized_transform, 1](k - 1)  # Process k-1 elements (indices 1 to k-1)

#     fn rfft(mut self, mut real: List[Float64]):
#         """Real-valued Fast Fourier Transform."""
#         ptr: UnsafePointer[Float64] = UnsafePointer(to=real[0])

#         n = len(real)
#         self.rfft(n, ptr)

#     fn irfft(mut self, n: Int, mut real: UnsafePointer[Float64]):
#         """Inverse Real-valued Fast Fourier Transform."""
#         var k = n // 2
#         for i in range(1, k):
#             var j = n - 1 - i
#             var a = real[i]
#             var b = real[j]
#             real[j] = a - b
#             real[i] = a + b
        
#         self.fht(real, n)

#     fn irfft(mut self, mut real: List[Float64]):
#         """Inverse Real-valued Fast Fourier Transform."""
#         ptr: UnsafePointer[Float64] = UnsafePointer(to=real[0])

#         n = len(real)
#         self.irfft(n, ptr)

#     @staticmethod
#     fn py_rfft(py_self: UnsafePointer[Self], args: PythonObject) raises -> PythonObject:
#         """Fast Fourier Transform."""
#         length = len(args)

#         var pointer = args.__array_interface__["data"][0].unsafe_get_as_pointer[DType.float64]()
#         py_self[0].rfft(length, pointer)

#         return PythonObject(None)

# @export
# fn PyInit_MMM_FFT() -> PythonObject:
#     """Python initialization function for MMM_FFT."""
#     try:
#         var mb = PythonModuleBuilder("MMM_FFT")

#         _ = (
#             mb.add_type[MMM_FFT]("MMM_FFT")
#             .def_py_init[MMM_FFT.py_init]()
#             # .def_method[MMM_FFT.py_fft]("fft")
#             # .def_method[MMM_FFT.ifft]("ifft")
#             .def_method[MMM_FFT.py_rfft]("py_rfft")
#             # .def_method[MMM_FFT.irfft]("irfft")
#         )

#         return mb.finalize()
#     except Exception:
#         print("Error initializing MMM_FFT")
#         return None