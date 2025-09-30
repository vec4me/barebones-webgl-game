interp_module := {}
{
	fn interp_module.make(targs, style) {
		interp := {}
		l := targs.length
		fn interp.sample(t) {
			i := floor(t*targs.length)
			v0 := vector.make(...targs[(i + 0)%l])
			v1 := vector.make(...targs[(i + 1)%l])
			if style == "quat" {
				// return v0.slerp(v1, x)
				return v0
			}
			return v0
		}
		return interp
	}
}
