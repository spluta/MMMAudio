import mojo.importer
import sys
sys.path.insert(0, "mmm_audio")

import MBufAnalysisBridge

class MBufAnalysis:
    
    @staticmethod
    def rms(dict:dict):
        return MBufAnalysisBridge.rms(dict)
    
    @staticmethod
    def custom_analysis(dict:dict):
        return MBufAnalysisBridge.custom(dict)