IronPythonScope
=======

An IronPythonScope object can be seen as a namespace. One can store name-object pairs in this space. The properties and methods are listed below.

Properties
-------

Methods
-------
###IronPythonScope
obj = IronPythonScope([optional]scope)<br/>
Constructor of IronPythonScope.<br/>
Return value: a IronPythonScope object.<br/><br/>
Example:<br/>
\>\> scope = IronPythonScope();

###GetVariable
result = IronPythonScopeObject.GetVariable(name)<br/>
Get the value of a variable stored in IronPythonScopeObject via its name.<br/>
name: the name of the varaible.<br/>
Return value: the value of the variable.<br/><br/>
Example:<br/>
\>\> scope.SetVariable('a', 10);<br/>
\>\> scope.GetVariable('a')

###SetVariable
IronPythonScopeObject.SetVariable(name, val)<br/>
Create a new name in IronPythonScopeObject and bind a value to it.<br>
name: the name of the new variable.<br/>
val:  the value of the new variable.<br/>
Return value: void.<br/><br/>
Example:<br/>
See GetVariable.

###GetBuiltin
result = IronPythonScopeObject.GetBuiltin(name)<br/>
Get a python builtin object via its name.<br/>
name: the name of the builtin object.<br/>
Return value: the specified builtin object.<br/><br/>
Example:<br/>
\>\> scope.GetBuiltin('str')

###ExecuteString
result = IronPythonScopeObject.ExecuteString(string)<br/>
Execute a python code string.<br/>
string: a python code string.<br/>
Return value: the value of the executed string.<br/><br/>
Example:<br/>
\>\> scope.ExecuteString('print "Hello"');

###evalin
ret = evalin(IronPythonScope, expr)<br/>
Evaluate a python code string in a given scope and return its value.<br/>
expr: a python expression string.<br/>
Return value: the value of the expression.<br/><br/>
Example:<br/>
\>\> scope1 = IronPythonScope();<br/>
\>\> scope2 = IronPythonScope();<br/>
\>\> scope1.SetVariable('a', 10);<br/>
\>\> scope2.SetVariable('a', 20);<br/>
\>\> evalin(scope1, 'a\*10')<br/>
100.0<br/>
\>\> evalin(scope2, 'a\*10')<br/>
200.0<br/>

###Import
result = IronPythonScopeObject.Import(mname)<br/>
Import a module and return the module object.<br/>
mname: the name of the module.<br/>
Return value: the module object.<br/><br/>
Example:<br/>
\>\>sys = scope.Import('sys')

###BuiltFunc
newfunc = IronPythonScopeObject.BuiltFunc(func)<br/>
Convert a matlab function handle into a python callable object.<br/>
func: a matlab function handle.<br/>
Return value: a python callable object.<br/><br/>
Example:<br/>
\>\> f = @(args, kwargs) GetPyObject(args(0)) + 100;<br/>
\>\> range = scope.GetBuiltin('range');<br/>
\>\> li = range(int32(10))<br/>
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]<br/>
\>\> pyf = scope.BuiltFunc(f);<br/>
\>\> map = scope.GetBuiltin('map');<br/>
\>\> map(pyf, li)<br/>
[100, 101, 102, 103, 104, 105, 106, 107, 108, 109]<br/>
More examples, see ![Call EnumWindows using Ipyinter](https://github.com/xialulee/Ipyinter/raw/master/examples/enum_win.m).<br/>
Notice:<br/>
The matlab function must using the exact form shown as follows:<br/>
function RetVal = f(args, kwargs)<br/>
...<br/>
end
