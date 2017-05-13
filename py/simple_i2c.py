import smbus
import time

bus = smbus.SMBus(1)    # 0 = /dev/i2c-0 (port I2C0), 1 = /dev/i2c-1 (port I2C1)

DEVICE_ADDRESS = 0x48     #7 bit address (will be left shifted to add the read write bit)

def write_smbus(addr, data):
    bus.write_word_data(DEVICE_ADDRESS, addr, (data<<8 & 0xFF00 | data>>8))

def write_variable(isWord, i_d, offset):
    reg = 0x0000
    reg = ((not isWord) << 15) | (1 << 13) | (i_d << 8) | (offset)
    print("Trying to write this reg: "+str(hex(reg)))
    write_smbus(0xC6, reg)

def read_smbus():
    ret = bus.read_word_data(DEVICE_ADDRESS, 0xC8)
    return hex((ret<<8 & 0xFF00 | ret>>8))

#Write a single register
#bus.write_byte_data(DEVICE_ADDRESS, DEVICE_REG_MODE1, 0x80)

#Write an array of registers
#ledout_values = [0xff, 0xff, 0xff, 0xff, 0xff, 0xff]
print("Reading Horizontal Blanking.")


print(bus.read_word_data(DEVICE_ADDRESS, 0x07))

def write_with_delay(add, reg, val):
    try:
        bus.write_word_data(add, reg,  val)
    except:
    	time.sleep(0.10)
    	write_with_delay(add, reg, val) 
def write_data(cmds):
    for c in cmds:
        reg, val = c
        #bus.write_word_data(DEVICE_ADDRESS, 0xF0, pg)
        bus.write_word_data(DEVICE_ADDRESS, reg, val)
	

cmds = [(0xF0, 0x1),
	(0xC6, 0x2702),
	(0xC8, 0x0)] 

write_smbus(0xF0, 0x0001)
write_variable(0, 1, 3)
write_smbus(0xC8, 1)

write_variable(0, 1, 4)
print(read_smbus())

write_smbus(0xF0, 0x0000)
write_smbus(0xF2, 0x0000)
write_smbus(0x07, 0x00AE)
write_smbus(0x08, 0x0010)
write_smbus(0x20, 0x0300)
write_smbus(0x21, 0x0490)

write_smbus(0xF0, 0x0001)

write_variable(1, 7, 3)
write_smbus(0xC8, 320)

write_variable(1, 7, 5)
write_smbus(0xC8, 240)

write_variable(0, 1, 2)
write_smbus(0xC8, 0x0E)

write_variable(0, 1, 34)
write_smbus(0xC8, 0x00)

write_variable(0, 1, 41)
write_smbus(0xC8, 0x00)

write_variable(1, 2, 31)
write_smbus(0xC8, 0x0D)
#print(read_smbus())

write_variable(1, 2, 34)
write_smbus(0xC8, 0x80)
#print(read_smbus())

write_variable(1, 2, 36)
write_smbus(0xC8, 0x2004)
#print(read_smbus())

write_variable(1, 2, 37)
write_smbus(0xC8, 1200)
#print(read_smbus())
'''
write_variable(1, 7, 39)
write_smbus(0xC8, 0)

write_variable(1, 7, 41)
write_smbus(0xC8, 320)

write_variable(1, 7, 43)
write_smbus(0xC8, 0)

write_variable(1, 7, 45)
write_smbus(0xC8, 240)

write_variable(1, 7, 19)
write_smbus(0xC8, 640)

write_variable(1, 7, 21)
write_smbus(0xC8, 960)

write_variable(1, 7, 23)
write_smbus(0xC8, 0x0088)

write_variable(1, 7, 25)
write_smbus(0xC8, 0x0011)
'''
write_variable(0, 1, 3)
write_smbus(0xC8, 6)

write_variable(0, 1, 3)
write_smbus(0xC8, 5)




