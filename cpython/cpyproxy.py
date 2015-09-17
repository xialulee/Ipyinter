# -*- coding: utf-8 -*-
"""
Created on Thu Sep 17 16:53:47 2015

@author: Feng-cong Li
"""

# This module is for IronPython

import os
import ctypes as ct

class CPython(object):
    def initialize(self, cpyHome=None):
        if cpyHome is None:
            cpyHome = os.environ['PYTHONHOME']
        os.environ['PYTHONHOME'] = cpyHome
        pyPath  = os.environ.get('PYTHONPATH', '')
        folders = ['DLLs', 'Lib', 'Lib/site-packages']
        folderList = [os.path.join(cpyHome, folder) for folder in folders]
        folderList.append(pyPath)
        pyPath  = ';'.join(folderList)
        os.environ['PYTHONPATH'] = pyPath
        self.__cpyLib  = ct.cdll.LoadLibrary('python27.dll')
        self.__cpyLib.Py_Initialize()
        self.__cpyLib.PyImport_ImportModule.argtypes = [ct.c_char_p]
        self.__cpyLib.PyString_AsString.restype = ct.c_char_p
        
    def finalize(self):
        self.__cpyLib.Py_Finalize()
        
    def importModule(self, modName):
        modPtr = self.__cpyLib.PyImport_ImportModule(modName)
        return CPythonObject(modPtr, self)
        
    def getAttr(self, objPtr, attrName):
        return CPythonObject(self.__cpyLib.PyObject_GetAttrString(objPtr, attrName), self)
        
    def representation(self, objPtr):
        reprObj =  self.__cpyLib.PyObject_Repr(objPtr)
        return self.__cpyLib.PyString_AsString(reprObj)
        
    def decRef(self, objPtr):
        self.__cpyLib.Py_DECREF(objPtr)
        
class CPythonObject(object):
    def __init__(self, objPtr, cpy, borrowed=False):
        self.__objPtr   = objPtr
        self.__cpy      = cpy
        self.__borrowed = borrowed
        
    def __getattr__(self, attrName):
        return self.__cpy.getAttr(self.__objPtr, attrName)
        
    def __repr__(self):
        return self.__cpy.representation(self.__objPtr)
        
    def __del__(self):
        if self.__borrowed:
            self.__cpy.decRef(self.__objPtr)
    
        
        
if __name__ == '__main__':
    cpy   = CPython()
    cpy.initialize('c:/python27')
    cpyOs = cpy.importModule('os')
    print repr(cpyOs)
    cpy.finalize()