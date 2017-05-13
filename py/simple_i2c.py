import smbus
import time

bus = smbus.SMBus(1)    # 0 = /dev/i2c-0 (port I2C0), 1 = /dev/i2c-1 (port I2C1)

DEVICE_ADDRESS = 0x48     #7 bit address (will be left shifted to add the read write bit)



def write_smbus(isWord, i_d, offset, val):
    reg = 0x0000
    reg = (isWord << 16) | (1 << 13) | (i_d << 8) | (offset)
    print("Trying to write this reg: "+str(hex(reg)))
    bus.write_word_data(DEVICE_ADDRESS, 0xC6, (reg<<8 & 0xFF00 | reg>>8))

def read_smbus():
    ret = bus.read_word_data(DEVICE_ADDRESS, 0xC8)
    print("Returned: "+ str(hex((ret<<8 & 0xFF00 | ret>>8))))

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
bus.write_word_data(DEVICE_ADDRESS, 0xF0, 0x0100)
bus.write_word_data(DEVICE_ADDRESS, 0xC6, 0x03A1)
print(hex(bus.read_word_data(DEVICE_ADDRESS, 0xC8)))

bus.write_word_data(DEVICE_ADDRESS, 0xC6, 0x04A1)
print(hex(bus.read_byte_data(DEVICE_ADDRESS, 0xC8)))    
#bus.write_word_data(DEVICE_ADDRESS, 0xF0, 0x01)

bus.write_word_data(DEVICE_ADDRESS, 0xC6, 0x03A1)
bus.write_word_data(DEVICE_ADDRESS, 0xC8, 0x0100)

bus.write_word_data(DEVICE_ADDRESS, 0xC6, 0x03A1)
print("CMD:"+str(hex(bus.read_word_data(DEVICE_ADDRESS, 0xC8))))

bus.write_word_data(DEVICE_ADDRESS, 0xC6, 0x04A1)
print("State:"+str(hex(bus.read_word_data(DEVICE_ADDRESS, 0xC8))))

