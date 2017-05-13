# Simple Hex/Dec/Fixed Point Convertor
# Raghava Kumar (rk534)
# 28th March 2017


# Converts given hex value to float, assuming a.b fixed point notation
def fix_to_float(h, a, b):
  return fixdec_to_float(hex_to_dec(h, True, a + b), b)


# Converts given float to hex, assuming a.b fixed point notation
def float_to_fix(f, a, b):
  return dec_to_hex(float_to_fixdec(f, b), a + b)


# Helper: Converts given decimal value to float, assuming a.b fixed point notation
def fixdec_to_float(d, b):
  return float(d)/(2**b)


# Helper: Converts given float value to decimal, assuming a.b fixed point notation
def float_to_fixdec(f, b):
  return int(f*(2**b))


# Helper: Converts signed/unsigned n-bit hex value to decimal
def hex_to_dec(h, signed=False, n=32):
  dec_val = int(h)

  if signed and dec_val > (2**(n-1))-1:
    dec_val -= 2**n

  return dec_val


# Helper: Converts a +ve/-ve decimal value to an n-bit signed hex
def dec_to_hex(d, n=32):
  if d >= 0:
    return hex(d)
  else:
    return hex((d + 2**n))