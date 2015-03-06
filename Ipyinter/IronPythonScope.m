classdef IronPythonScope < handle
% The wrapper class of the IronPython scope
% 
% Constructor
%   IronPythonScope(scope)
%     scope: an IronPython scope object
%
% Methods
%   Import: import modules in this scope
%   GetVariable: get a variable lies in this scope
%   SetVariable: put a object into the scope using a specified name
%   GetBuiltin: get a builtin object
%   ExecuteString: run a python program string in this scope
%
% Matlab 7.14 IronPython 2.7.3
% xialulee 2012.08.16
%
% Modified 2012.10.23
    
    properties (SetAccess = private)
        scope;
    end
    
    properties (Access = private)
        builtins;
        built_func;
        built_tuple;
        builtin_eval;
    end
    
    properties (SetAccess = private, Dependent)
        engine;
    end
    
    properties (Access = private)
        meaning_of_bracket;
    end
    
    properties (Dependent)
        MeaningOfBracket;
    end    
    
    methods
        function val = get.MeaningOfBracket(obj)
            val = obj.meaning_of_bracket;
        end
        
        function set.MeaningOfBracket(obj, val)
            if ~any(cellfun(@(item)strcmp(item, val), {'auto', 'call', 'indexing'}))
                error('The valid value of MeaningOfBracket are "auto", "call", and "indexing".');
            end
            obj.meaning_of_bracket = val;
        end
    end
    
    methods
        function engine = get.engine(obj)
            engine = obj.scope.Engine;
        end
    end       
    
    methods (Static)
        function code = CSharpCode()
%             namespace MatlabIronPythonTools{
%                 public delegate object func(object args, object kwargs);
%             }   
            code = help('IronPythonScope.CSharpCode');
        end
    end
    
    methods (Static, Access = private)
        function dllgen()
            dllfile = fullfile(fileparts(mfilename('fullpath')), 'MatlabIronPythonTools.dll');
            NET.addAssembly('Microsoft.CSharp');
            provider = Microsoft.CSharp.CSharpCodeProvider();
            params = System.CodeDom.Compiler.CompilerParameters();
            params.OutputAssembly = dllfile;
            params.GenerateExecutable = false;
            code = IronPythonScope.CSharpCode();
            codearr = NET.createArray('System.String', 1);
            codearr.Set(0, code);
            provider.CompileAssemblyFromSource(params, codearr);        
        end
    end
    
    methods (Static)
        function ret = GetDefaultScope()
            persistent scopeobj;
            if isempty(scopeobj)
                pyasm = NET.addAssembly('IronPython');
                import IronPython.Hosting.*
                engineOpt = NET.createGeneric('System.Collections.Generic.Dictionary', {'System.String', 'System.Object'});
                engineOpt.Add('Frames', true);
                engineOpt.Add('FullFrames', true); 
                % see http://stackoverflow.com/questions/6997832/ironpython-sys-getframe-not-found
                engine = Python.CreateEngine(engineOpt);
                paths = engine.GetSearchPaths();
%                 pypath = fileparts(char(pyasm.AssemblyHandle.Location)); 
%                 pypath = fullfile(pypath, 'Lib')
%                 paths.Add(pypath); 
%                Not working. You should set environment variable
%                IRONPYTHONPATH
                dllname = fullfile(fileparts(mfilename('fullpath')), 'MatlabIronPythonTools.dll');
                if ~exist(dllname, 'file')
                    IronPythonScope.dllgen();
                end                
                scopeobj = IronPythonScope(engine.CreateScope());                
                fname = fullfile(fileparts(mfilename('fullpath')),'pythonpath');
                if exist(fname, 'file')                    
                    f = fopen(fname, 'rt');
                    while ~feof(f)
                        paths.Add(fgetl(f));
                    end
                    fclose(f);                    
                end
                ironpath = getenv('IRONPYTHONPATH');
                if ironpath
                    paths.Add(ironpath);
                end
                engine.SetSearchPaths(paths);
            end

            ret = scopeobj;
        end
    end    
    
    methods
        function obj = IronPythonScope(scope)
            if nargin == 0
                default_scope = IronPythonScope.GetDefaultScope();
                scope = default_scope.engine.CreateScope();
            end
            obj.scope = scope;
            obj.engine.CreateScriptSourceFromString('').Execute(scope);            
            obj.builtins = obj.scope.GetVariable('__builtins__');
            obj.builtin_eval = obj.GetBuiltin('eval');
            obj.built_func = Invoke(obj.builtin_eval, 'lambda f: lambda *args, **kwargs: f(args, kwargs)');
            obj.built_tuple = Invoke(obj.builtin_eval, 'lambda *args: args');
            obj.MeaningOfBracket = 'auto';
            
            % start set stdout and stderr
            sys = obj.Import('sys');
            type = obj.GetBuiltin('type');
            dict = obj.GetBuiltin('dict');                        
            function func = write_func_gen(file)
                function ret = write(args, ~)
                    fprintf(file, '%s', char(args(1)));
                    ret = 0;
                end
                func = @write;
            end
            stdout_methods = dict();
            stdout_methods('write') = obj.BuiltFunc(write_func_gen(1));
            StdOutClass = type('MatlabStdout', obj.BuiltTuple(), stdout_methods);
            sys.stdout = StdOutClass();
            stderr_methods = dict();
            stderr_methods('write') = obj.BuiltFunc(write_func_gen(2));
            StdErrClass = type('MatlabStderr', obj.BuiltTuple(), stderr_methods);
            sys.stderr = StdErrClass();
            % end set stdout and stderr
        end
        
        function result = GetVariable(obj, name)
            r = obj.scope.GetVariable(name);
            result = IronPythonObject(r, obj);
        end
        
        function SetVariable(obj, name, val)
            if isa(val, 'IronPythonObject')
                val = GetPyObject(val);
            end
            obj.scope.SetVariable(name, val);
        end
        
        function result = GetBuiltin(obj, name)
            r = obj.builtins.Item(System.String(name));
            result = IronPythonObject(r, obj);
        end
        
        function result = ExecuteString(obj, s)
            result = obj.engine.CreateScriptSourceFromString(s).Execute(obj.scope);
            result = IronPythonObject(result, obj);
        end
        
        function ret = evalin(obj, expr)
            ret = obj.ExecuteString(expr);
        end
        
        function result = Import(obj, mname)
            r = Invoke(obj.GetBuiltin('__import__'), mname);
            result = IronPythonObject(r, obj);
        end
        
        function newfunc = BuiltFunc(obj, func)
            persistent initialed;
            if isempty(initialed)
                NET.addAssembly(fullfile(fileparts(mfilename('fullpath')),'MatlabIronPythonTools.dll'));
                initialed = true;
            end

            function ret = wrapper_func(args, kwargs)
                args = IronPythonObject(args, obj);
                kwargs = IronPythonObject(kwargs, obj);
                ret = func(args, kwargs);
            end
            newfunc = obj.built_func(MatlabIronPythonTools.func(@wrapper_func));
            funcdoc = help(char(func));
            newfunc.('__doc__') = funcdoc;
            newfunc.('__name__') = char(func);
        end
        
        function tp = BuiltTuple(obj, varargin)
            for item = varargin
                if ~isscalar(item{1}) && ~ischar(item{1})
                    error('Array and matrix is not supported');
                end
            end
            tp = obj.built_tuple(varargin{:});
        end
    end
    
end