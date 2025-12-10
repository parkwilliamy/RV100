import serial

# MAKE SURE INPUT HANDLING WORKS AT THE END (ie, proper data/file format)

def main():
    
    while (1):
        mode = "".join(input("Enter R for Read Mode, Enter W for Write Mode: ").split())
        if mode == "R" or mode == "W":
            break

    MEM_SIZE = 0x8000
    ADDR_LOW = -1
    ADDR_HIGH = -1
    
    if mode == "R":
        while (ADDR_LOW < 0 or ADDR_LOW > MEM_SIZE or ADDR_LOW % 4 != 0):
            ADDR_LOW = "".join(input(f"Enter start address, must be a multiple of 4 and between 0 and {hex(MEM_SIZE)}: ").split())
            ADDR_LOW = int(ADDR_LOW, 0)

        while (ADDR_HIGH < ADDR_LOW or ADDR_HIGH > MEM_SIZE or ADDR_HIGH % 4 != 0):
            ADDR_HIGH = "".join(input(f"Enter end address, must be a multiple of 4 and between {hex(ADDR_LOW)} and {hex(MEM_SIZE)}: ").split())
            ADDR_HIGH = int(ADDR_HIGH, 0)

    elif mode == "W":
        MEM_FILE = "".join(input(f"Enter path to program/data file, must be .hex format: ").split())

    # remaining steps: break up file into words, create function to send write/read frames, determine memory view format


if __name__ == "__main__":
    main()