from mmm_audio import *
from testing import assert_true

def main():
    # Test TRand
    trand = TRand()
    
    trand0 = trand.next(10.0,20.0,False)
    assert_true(trand0 >= 10.0 and trand0 <= 20.0, "TRand initial output out of range")

    trand1 = trand.next(10.0,20.0,True)
    assert_true(trand1 >= 10.0 and trand1 <= 20.0, "TRand output after trigger out of range")
    assert_true(trand1 != trand0, "TRand did not change output after trigger")

    # Test TExpRand
    texprand = TExpRand()

    texprand0 = texprand.next(10.0,20.0,False)
    assert_true(texprand0 >= 10.0 and texprand0 <= 20.0, "TExpRand initial output out of range")

    texprand1 = texprand.next(10.0,20.0,True)
    assert_true(texprand1 >= 10.0 and texprand1 <= 20.0, "TExpRand output after trigger out of range")
    assert_true(texprand1 != texprand0, "TExpRand did not change output after trigger")

    print("All tests passed.")