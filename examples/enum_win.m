function result = enum_win()
% 2012.10.11 PM 09:20
% xialulee
    sc = IronPythonScope.GetDefaultScope();
    ct = sc.Import('ctypes');
    function ret = ew_callback(args, ~)
        hwnd = args(0);
        sz = int32(512);
        buf = Invoke(ct.c_char * sz);
        Invoke(ct.windll.user32.GetClassNameA, hwnd, buf, sz);
        buf.value
        ret = int32(1);
    end
    CALLBACK = ct.WINFUNCTYPE(ct.c_long, ct.c_long, ct.c_long);
    pyew_callback = CALLBACK(sc.BuiltFunc(@ew_callback));
    result = Invoke(ct.windll.user32.EnumWindows, pyew_callback, int32(0));
end