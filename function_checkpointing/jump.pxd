# Copied & modified from
#    https://github.com/Elizaveta239/frame-eval

from cpython.mem cimport PyMem_Malloc, PyMem_Free

cdef extern from *:
    ctypedef void PyObject
    ctypedef struct PyCodeObject:
        int co_argcount;		# arguments, except *args
        int co_kwonlyargcount;	# keyword only arguments
        int co_nlocals;		    # local variables
        int co_stacksize;		# entries needed for evaluation stack
        int co_flags;		    # CO_..., see below
        int co_firstlineno;     # first source line number
        PyObject *co_code;		# instruction opcodes
        PyObject *co_consts;	# list (constants used)
        PyObject *co_names;		# list of strings (names used)
        PyObject *co_varnames;	# tuple of strings (local variable names)
        PyObject *co_freevars;	# tuple of strings (free variable names)
        PyObject *co_cellvars;  # tuple of strings (cell variable names)
        unsigned char *co_cell2arg; # Maps cell vars which are arguments.
        PyObject *co_filename;	# unicode (where it was loaded from)
        PyObject *co_name;		# unicode (name, for reference)
        PyObject *co_lnotab;	# string (encoding addr<->lineno mapping) See
                                # Objects/lnotab_notes.txt for details.
        void *co_zombieframe;   # for optimization only (see frameobject.c)
        PyObject *co_weakreflist;   # to support weakrefs to code objects
        void *co_extra;

cdef extern from "genobject.h":
    ctypedef struct PyGenObject:
        PyFrameObject *gi_frame
        char gi_running
        PyObject *gi_code
        PyObject *gi_weakreflist
        PyObject *gi_name
        PyObject *gi_qualname
        # ...

cdef extern from "opcode.h":
    cdef int EXCEPT_HANDLER        # #defined as an integer
    cdef int JUMP_ABSOLUTE
    cdef int FOR_ITER

cdef extern from "frameobject.h":
    ctypedef struct PyTryBlock:
        int b_type                 # what kind of block this is
        int b_handler              # where to jump to find handle
        int b_level                # value stack level to pop to

    ctypedef struct PyFrameObject:
        PyFrameObject *f_back
        PyCodeObject *f_code       # code segment
        PyObject *f_builtins       # builtin symbol table (PyDictObject)
        PyObject *f_globals        # global symbol table (PyDictObject)
        PyObject *f_locals         # local symbol table (any mapping)
        PyObject **f_valuestack   #
        PyObject **f_stacktop
        PyObject *f_trace         # Trace function */
        PyObject *f_exc_type
        PyObject *f_exc_value
        PyObject *f_exc_traceback
        PyObject *f_gen;

        int f_lasti;                # Last instruction if called
        int f_lineno;               # Current line number
        int f_iblock;               # index in f_blockstack
        char f_executing;           # whether the frame is still executing
        PyTryBlock f_blockstack[1]  # for try and loop blocks
        PyObject *f_localsplus[1]

cdef extern from "code.h":
    ctypedef void freefunc(void *)
    int _PyCode_GetExtra(PyObject *code, Py_ssize_t index, void **extra)
    int _PyCode_SetExtra(PyObject *code, Py_ssize_t index, void *extra)

cdef extern from "Python.h":
    void Py_INCREF(object o)
    void Py_DECREF(object o)
    void Py_REFCNT(object o)
    object PyImport_ImportModule(char *name)
    PyObject* PyObject_CallFunction(PyObject *callable, const char *format, ...)
    object PyObject_GetAttrString(object o, char *attr_name)
    void PyErr_Clear()

cdef extern from "pystate.h":
    ctypedef object _PyFrameEvalFunction(PyFrameObject *frame, int exc)

    ctypedef struct PyInterpreterState:
        PyInterpreterState *next
        PyInterpreterState *tstate_head

        PyObject *modules

        PyObject *modules_by_index
        PyObject *sysdict
        PyObject *builtins
        PyObject *importlib

        PyObject *codec_search_path
        PyObject *codec_search_cache
        PyObject *codec_error_registry
        int codecs_initialized
        int fscodec_initialized

        int dlopenflags

        PyObject *builtins_copy
        PyObject *import_func
        # Initialized to PyEval_EvalFrameDefault().
        _PyFrameEvalFunction eval_frame

    ctypedef struct PyThreadState:
        PyThreadState *prev
        PyThreadState *next
        PyInterpreterState *interp
        PyFrameObject *frame
        int recursion_depth
        # ...

    PyThreadState *PyThreadState_Get()

cdef extern from "ceval.h":
    int _PyEval_RequestCodeExtraIndex(freefunc)
    PyFrameObject *PyEval_GetFrame()
    PyObject* PyEval_CallFunction(PyObject *callable, const char *format, ...)

    object _PyEval_EvalFrameDefault(PyFrameObject *frame, int exc)
