math_pipeline_module := {}
{
	operator_map := {
		"+": "add",
		"*": "mul",
		".": "dot",
		"^": "cross"
	}

	// Function to parse and transform the AST manually
	fn parse_and_transform(expression) {
		fn tokenize(expr) {
			tokens := []
			let current = ""
			for let char of expr {
				if "+*^.".includes(char) {
					if (current.trim()) tokens.push(current.trim())
					tokens.push(char)
					current = ""
				}
				else {
					current += char
				}
			}
			if (current.trim()) tokens.push(current.trim())
			return tokens
		}

		tokens := tokenize(expression)
		let i = 0
		fn transform_tokens() {
			let left = tokens[i++]
			while i < tokens.length {
				operator := tokens[i++]
				right := tokens[i++]
				method := operator_map[operator]
				if !method {
					throw new error("unsupported operator: ${operator}")
				}
				left = "${left}.${method}(${right})"
			}
			return left
		}
		return transform_tokens()
	}

	// fn transform_function(func) {
	// 	func_string := func.to_string()
	// 	body_match := func_string.match(/=>\s*{([\s\S]*)}/)
	// 	if !body_match {
	// 		throw new error("invalid function format")
	// 	}
	// 	let body = body_match[1].trim()

	// 	if body.starts_with("return") {
	// 		body = body.replace(/^return\s+/, "")
	// 		if body.ends_with(";") {
	// 			body = body.slice(0, -1)
	// 		}
	// 	}

	// 	transformed_body := parse_and_transform(body)
	// 	transformed_func := new Function("a", "b", "return ${transformed_body};")
	// 	return transformed_func
	// }

	// fn source_function(a, b) {
	// 	return a . b + a ^ b + a * b + a + b
	// }

	// transformed_func := transform_function(source_function.to_string())
	// console.log(transformed_func.to_string())

	a := {
		dot: fn(other) {
			console.log("called dot")
			return 100
		},
		cross: fn(other) {
			console.log("called cross")
			return 200
		},
		add: fn(other) {
			console.log("called add")
			return 5 + other
		},
		mul: fn(other) {
			console.log("called mul")
			return 5 * other
		},
		value: 5
	}

	b := 3

	// transformed_result := transformed_func(a, b)

	// console.log("transformed function result", transformed_result)
}
