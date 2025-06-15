import dis
import marshal
import sys
from collections import defaultdict

def count_instr(file_path):
    if not file_path.endswith('.pyc'):
        print("Please provide a .pyc file")
        return

    with open(file_path, 'rb') as f:
        f.read(16)

        code_obj = marshal.load(f)

    instruction_count = defaultdict(int)
    bytecode = dis.Bytecode(code_obj)

    for instruction in bytecode:    
        instruction_count[instruction.opname] += 1

    print(f"Instruction counts for {file_path}:")
    for instruction, count in instruction_count.items():
        print(f"{instruction}: {count}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python count_instructions.py <file.pyc>")
    else:
        file_path = sys.argv[1]
        count_instr(file_path)
