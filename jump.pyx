import hashlib

funcall_log = {}
modules = []

def fixup_lasti(frame, last_is):
    cdef PyFrameObject *f = <PyFrameObject *> frame
    i = 0
    while f:
        f.f_lasti = last_is[i]
        f = f.f_back
        i += 1

def print_frame(frame):
    cdef PyFrameObject *f = <PyFrameObject *> frame

    if not frame:
        return 0

    indent = print_frame(frame.f_back)

    print ' ' * indent, frame.f_locals.get('func', '?'), f.f_lasti

    return indent + 1


cdef hash_code(f_code):
  h = hashlib.sha1(f_code.co_code)
  h.update(str(f_code.co_consts).encode("utf-8"))
  return h.digest()

cdef PyObject* _log_funcall_entry(PyFrameObject *frame, int exc):
  frame_obj = <object> frame
  cdef PyThreadState *state = PyThreadState_Get()

  # to ovoid the overhead of this call, log only if the function is in
  # the desired modules.
  if frame_obj.f_code.co_filename not in modules:
      state.interp.eval_frame = _PyEval_EvalFrameDefault
      r = _PyEval_EvalFrameDefault(frame, exc)
      state.interp.eval_frame = _log_funcall_entry
      return r

  print("---------Tracing-----")
  print(frame_obj.f_code.co_filename, frame_obj.f_code.co_name)

  # keep a fully qualified name for the function. and a sha1 of its code.
  # if we hold references to the frame object, we might cause a lot of
  # unexpected garbage to be kept around.
  funcall_log[(frame_obj.f_code.co_filename, frame_obj.f_code.co_name)] = hash_code(
      frame_obj.f_code
  )

  return _PyEval_EvalFrameDefault(frame, exc)

def trace_funcalls(module_fnames):
    cdef PyThreadState *state = PyThreadState_Get()
    modules.clear()
    modules.extend(module_fnames)
    state.interp.eval_frame = _log_funcall_entry
    
def stop_trace_funcalls():
    cdef PyThreadState *state = PyThreadState_Get()
    state.interp.eval_frame = _PyEval_EvalFrameDefault
