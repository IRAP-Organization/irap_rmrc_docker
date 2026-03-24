from arduino.app_utils import *

def python_func(data: int):
    print("value =", data)

Bridge.provide("python_func", python_func)

App.run()
