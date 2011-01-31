About state-dispatch
--------------------

state-dispatch provides a method combination for dispatch on the state of an object in a matter similar to UnrealScript where the state is represented by a stack of items.
A crucial difference, though - only the most specific form of a method is called upon.
An object has a stack of states - they can be pushed on or popped. Alternatively, a simpler interface is provided that will set the top item on the stack of states.
A method combination is then provided that will dispatch on the state of an object. It is rather awkward - a replacement defstatemethod is used to provide introspection at runtime, thanks to the limitations of define-method-combination.

The State Dispatch Dictionary
-----------------------------

** *Class* stateable-object

Base class with the "state-stack" slot.

** *Method combination* :state

Method combination that will dispatch on the top value of state-stack. It will #'equal on both the specifier given with a method and the top item on the state-stack of an object and will then dispatch.
The same caveat above applies with the extra note that no hierarchy of specifiers exists just yet.
no-method-for-state is signaled when there is no method for a state. Two restarts are given - one sets the state and one simply returns a value.

** *Condition* no-method-for-state

Signaled when there is no-method-for-state (of the object) as clled by the method combination. Contains slots for the object, its state-stack, the generic function, and its methods.

** *Accessor* state

Gives the state of an object. In its setf form it will set the state-stack to it and the existing #'rest of the state-stack.

** *Function* push-state and *Function* pop-state

Pushes and pops the state off the state-stack.