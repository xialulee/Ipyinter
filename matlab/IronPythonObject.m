classdef IronPythonObject < handle
% A Class encapsulating an IronPython object
% 
%   If you want to access the members of the Python object ,
%     use the following syntax:
%
%     obj.properties
%
%   For example
%   >> scope = IronPythonScope.GetDefaultScope;
%   >> os = scope.Import('os');
%   >> cur = os.listdir('.')
%   ['backup', 'datatype', 'datatype.zip']
%   >> cur(0)
%   'backup'
% 
%   If the python object is callable, the syntax
%     obj(parameters)
%   will call the obj, else it will call the __getitem__ method of the obj.
%   If a object support both __call and __get/setitem__, you have to call
%   the __get/setitem__ method explicitly.
% 
%
%   If you want to call the methods defined in the IronPythonObject class
%     use the following syntax:
%
%     methodname(obj, parameters)
% 
%   For example
%   >> GetAttr(os, 'listdir')
%   <built-in function listdir>
%
%   Or you can use builtin('subsref'/'subsasgn' ...
% 
%
% Constructor
%   IronPythonObject(pyobj, scope)
%     pyobj:    an IronPython object or an instance of IronPythonObject class
%     scope:    an instance of IronPythonScope class
%
% Properties
%   DefaultDisplay
%     if true, the builtin display function will be used to display the
%     object;
%     if false, the content of repr of the underlying Python object will be
%     used to display.
%     Default value: false.
%
%
%   pyobj
%     the underlying Python object
% 
% Operators
%   supported operators:
%     +, -, *, /, ^, <, >, <=, >=, ==, ~=
%   supported type convertion operators:
%     char logical double int32 cell
%
% Methods
%   Invoke
%     if the underlying Python object is a callable object, invoke this
%     object.
%
%   GetAttr
%     get an attribute of the underlying Python object. equivalent to
%     Python getattr function.
%
%   Callable
%     return true if the python object is callable
%
% Matlab 7.14 IronPython 2.7.1
% xialulee 2012.08.14
%
% Modified: 2012.10.23



    
    properties 
        DefaultDisplay = false;
    end
    
    properties (SetAccess = private)
        pyobj;
        scope;
        engine;        
    end
        
    
    methods 
        function engine = get.engine(obj)
            engine = obj.scope.engine;
        end
        
        function result = str(obj)
            r = obj.scope.GetBuiltin('str').Invoke(obj);
            result = char(r.pyobj);
        end
        
        function result = repr(obj)
            r = obj.scope.GetBuiltin('repr').Invoke(obj);
            result = char(r.pyobj);            
        end
        
        function result = len(obj)
            result = obj.scope.GetBuiltin('len').Invoke(obj);
        end
        
        function result = help(obj)
            document = char(obj.scope.engine.Operations.GetDocumentation(obj.pyobj));
            if nargout == 0
                fprintf([document, '\n']);
            else
                result = document;
            end
        end
        
        function result = dir(obj)
            result = obj.scope.GetBuiltin('dir').Invoke(obj);
        end
        
        function result = id(obj)
            result = obj.scope.GetBuiltin('id').Invoke(obj);
        end
    end
    
    methods (Access = private, Static)
        function params = ConstructParamsArray(varargin)                 
            params = NET.createArray('System.Object', nargin);
            for idx = 1 : nargin
                p = varargin{idx};
                if isa(p, 'char') && numel(p)==1
                    %{
                    For a char array with a single element,
                      Matlab will convert it to a Char type rather than
                      String. However, we need a String for IronPython
                    %}
                    p = System.String(p);
                end
                if isa(p, 'IronPythonObject')
                    p = p.pyobj;
                end
                params.Set(idx-1, p);
            end            
        end 
        
        function [x, y, stat] = SortParams(x, y)
            stat = false;
            if ~isa(x, 'IronPythonObject')
                tmp = x;
                x = y;
                y = tmp;
                stat = true;
            end
        end
    end
        
    methods (Access = private)
        function result = InvokeOperator(obj, y, op)
            y = obj.GetObject(y);
            r = obj.engine.Operations.(op)(obj.pyobj, y);
            result = IronPythonObject(r, obj.scope);
        end   
        
        function result = InvokeOperatorMethodEx(obj, y, op, pre, post)
            if isa(pre, 'function_handle')
                y = pre(y);
            else
                y = obj.GetObject(y);
            end
            try
                r = obj.GetAttr(op{1}).Invoke(y).pyobj;
            catch e
                if isa(e.ExceptionObject, 'System.MissingMemberException') 
                    r = obj.InvokeOperator(y, op{2}).pyobj;
                end
            end
            if isa(post, 'function_handle')
                result = post(r);
            else
                result = IronPythonObject(r, obj.scope);
            end
        end
        
        function x = GetObject(obj, x)
            if isa(x, class(obj))
                x = x.pyobj;
            end
        end     
        
        function result = GetCompareResult(obj, ironpyobj)
            if isa(ironpyobj, 'logical')
                result = ironpyobj;
            else
                result = IronPythonObject(ironpyobj, obj.scope);
            end
        end        
    end
    
    methods
        function obj = IronPythonObject(pyobj, scope)
            pyobj = obj.GetObject(pyobj);
            obj.pyobj = pyobj;
            obj.scope = scope;
        end
        
        function pyobj = GetPyObject(obj)
            pyobj = obj.pyobj;
        end
        
        function result = plus(obj, y)
            % operator +
            [obj, y] = IronPythonObject.SortParams(obj, y);
            result = obj.InvokeOperator(y, 'Add');
        end
        
        function result = minus(obj, y)
            % operator -
            [obj, y] = IronPythonObject.SortParams(obj, y);
            result = obj.InvokeOperator(y, 'Subtract');            
        end
        
        function result = mtimes(obj, y)
            % operator *
            [obj, y] = IronPythonObject.SortParams(obj, y);
            result = obj.InvokeOperator(y, 'Multiply');            
        end
        
        function result = mrdivide(obj, y)
            % operator /
            [obj, y] = IronPythonObject.SortParams(obj, y);
            result = obj.InvokeOperator(y, 'Divide');            
        end
        
        function result = mpower(obj, y)
            % operator ^
            [obj, y] = IronPythonObject.SortParams(obj, y);
            result = obj.InvokeOperator(y, 'Power');            
        end     
        
        %{
        Implement the compare operators
        The return values of compare operators implemented in ObjectOperations
        is type bool.
        However, the compare operation of some Python object is not
        simply a bool, for example:
          >>> from sympy.abc import *
          >>> type(x > y)
          <class 'sympy.core.relational.StrictInequality'>
        Hence the operators here is implemented using objects' compare
        methods directly.
        %}
        
        function result = eq(obj, y)
            % operator ==
            [obj, y] = IronPythonObject.SortParams(obj, y);
            result = obj.InvokeOperatorMethodEx(y, {'__eq__', 'Equal'}, false, @obj.GetCompareResult);
        end
        
        function result = gt(obj, y)
            % operator >
            [obj, y, stat] = IronPythonObject.SortParams(obj, y);
            if stat
                result = lt(obj, y);
            else
                result = obj.InvokeOperatorMethodEx(y, {'__gt__', 'GreaterThan'}, false, @obj.GetCompareResult);
            end
        end
        
        function result = ge(obj, y)
            % operator >=
            [obj, y, stat] = IronPythonObject.SortParams(obj, y);
            if stat
                result = le(obj, y);
            else
                result = obj.InvokeOperatorMethodEx(y, {'__ge__', 'GreaterThanOrEqual'}, false, @obj.GetCompareResult);
            end
        end
        
        function result = lt(obj, y)
            % operator <
            [obj, y, stat] = IronPythonObject.SortParams(obj, y);
            if stat
                result = gt(obj, y);
            else
                result = obj.InvokeOperatorMethodEx(y, {'__lt__', 'LessThan'}, false, @obj.GetCompareResult);
            end
        end
        
        function result = le(obj, y)
            % operator <=
            [obj, y, stat] = IronPythonObject.SortParams(obj, y);
            if stat
                result = ge(obj, y);
            else
                result = obj.InvokeOperatorMethodEx(y, {'__le__', 'LessThanOrEqual'}, false, @obj.GetCompareResult);
            end
        end
        
        function result = ne(obj, y)
            % operator ~=
            [obj, y] = IronPythonObject.SortParams(obj, y);
            result = obj.InvokeOperatorMethodEx(y, {'__ne__', 'NotEqual'}, false, @obj.GetCompareResult);
        end
        
        function display(obj)
            if obj.DefaultDisplay
                builtin('disp', obj);
            else
                disp(obj.repr);
            end
        end        
        
        function result = subsref(obj, S)
            % Within a class's own methods, MATLAB calls the built-in subsref, not the class defined subsref.

            result = obj;
            for n = 1 : numel(S)
                switch S(n).type
                    case '()'
                        if ~strcmp(obj.scope.MeaningOfBracket, 'indexing') && (strcmp(obj.scope.MeaningOfBracket, 'call') || result.Callable)
                            result = Invoke(result, S(n).subs{:});
                        else
                            for m = 1 : numel(S(n).subs)
                                idx = S(n).subs{m};
                                if isa(idx, 'char')
                                    S(n).subs{m} = System.String(idx);
                                end
                                if isnumeric(idx)
                                    intidx = int32(idx);
                                    if all(idx == intidx)
                                        idx = intidx;
                                    end
                                    if ~isscalar(idx)
                                        if any(diff(idx) ~= (idx(2)-idx(1)))
                                            error('Nonhomogeneous slice referencing is not supported');
                                        end                                          
                                        idx = Invoke(obj.scope.GetBuiltin('slice'), idx(1), idx(end), idx(2)-idx(1));
                                    end
                                    S(n).subs{m} = idx;
                                end
                            end
                            result = result.GetAttr('__getitem__').Invoke(S(n).subs{:});                            
                        end
                    case '.'
                        result = GetAttr(result, S(n).subs);
                end
            end 
            
        end
        
        function [obj, result] = subsasgn(obj, S, val)
            if numel(val) > 1 && ~isa(val, 'char')
                error('Only scalar is supported.');
            end
            result = obj;
            for n = 1 : numel(S)
                switch S(n).type
                    case '()'
                        for m = 1 : numel(S(n).subs)
                            idx = S(n).subs{m};
                            if isa(idx, 'char')
                                S(n).subs{m} = System.String(idx);
                            end
                            if isnumeric(idx)
                                intidx = int32(idx);
                                if all(idx == intidx)
                                    idx = intidx;
                                end
                                if ~isscalar(idx)
                                    if any(diff(idx) ~= (idx(2)-idx(1)))
                                        error('Nonhomogeneous slice referencing is not supported');
                                    end                                    
                                    idx = Invoke(obj.scope.GetBuiltin('slice'), idx(1), idx(end), idx(2)-idx(1));
                                end
                                S(n).subs{m} = idx;
                            end
                        end
                        if n == numel(S)
                            result = result.GetAttr('__setitem__').Invoke(S(n).subs{:}, val);                            
                        else
                            result = result.GetAttr('__getitem__').Invoke(S(n).subs{:});
                        end
                    case '.'
                        if n == numel(S)
                            result = SetAttr(result, S(n).subs, val);
                        else
                            result = GetAttr(result, S(n).subs);
                        end
                end
            end             
        end
        
        % Convert operations
        % Python Object to Matlab char array
        function s = char(obj)            
            s = str(obj);
        end
        
        % Python Object to Matlab logical
        function b = logical(obj)
            result = obj.scope.GetBuiltin('bool').Invoke(obj);
            b = result == obj.scope.GetBuiltin('True');                
        end
        
        % Python Object to Matlab int32
        function i = int32(obj)
            i = int32(obj.pyobj);
        end
        
        % Python Object to Matlab double
        function d = double(obj)
            d = double(obj.pyobj);
        end

        % Python container to Matlab cell array
        function ca = cell(obj)
            N = GetPyObject(obj.len());
            ca = cell(1, N);
            it = obj.scope.GetBuiltin('iter').Invoke(obj);
            for k = 1 : N
                ca{k} = Invoke(GetAttr(it, 'next'));
            end
        end        
                
        function result = GetAttr(obj, attrname)
            result = obj.scope.GetBuiltin('getattr').Invoke(obj, attrname);            
        end
        
        function result = SetAttr(obj, attrname, val)
            if isa(val, class(obj))
                val = GetPyObject(val);
            end
            result = obj.scope.GetBuiltin('setattr').Invoke(obj, attrname, val);
        end
        
        function result = Callable(obj)
            result = logical(obj.scope.GetBuiltin('callable').Invoke(obj).pyobj);
        end        

        function varargout = Unpack(obj)
            if Callable(obj)
                error('Callable object is not supported');
            end
            for k = 1 : nargout
                varargout{k} = Invoke(GetAttr(obj, '__getitem__'), int32(k-1));
            end
        end        
                
        function result = Invoke(obj, varargin)
            % __call__ of Python object
            params = obj.ConstructParamsArray(varargin{:});
            r = obj.engine.Operations.Invoke(obj.pyobj, params);
            result = IronPythonObject(r, obj.scope);
        end
        
        function result = InvokeMember(obj, membername, varargin)
            % Call Python object method
            params = obj.ConstructParamsArray(varargin{:});
            r = obj.engine.Operations.InvokeMember(obj.pyobj, membername, params);
            result = IronPythonObject(r, obj.scope);
        end        
    end
    
end