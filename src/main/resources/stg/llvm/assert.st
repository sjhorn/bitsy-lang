assert(value, scope, label, message, line) ::= <<
 ; assert line <line>
<compareValToZero(value, scope.register)>
br i1 %c<scope.register>, label %endif<label>, label %true<label>
true<label>:
	<println(message, scope)>
	call void @exit(i32 1)
	br label %endif<label>
endif<label>:
>>