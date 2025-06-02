INPUT_FILE = "events.txt"
OUTPUT_FILE = "events_updated.txt"

def update_lines_with_voice_fields(input_file, output_file):
    with open(input_file, "r", encoding="utf-8") as infile, open(output_file, "w", encoding="utf-8") as outfile:
        for line in infile:
            if line.strip().startswith("#") or not line.strip():
                # Copy comments and empty lines unchanged
                outfile.write(line)
            else:
                parts = line.strip().split(";")
                print('NB: ', len(parts))
                if len(parts) == 9:
                    print(parts)
                    # Insert empty voice_a after outcome_a (index 5)
                    parts.insert(5, "")  # voice_a
                    # Insert empty voice_b after outcome_b (index 8+1 due to prior insert)
                    parts.insert(8, "")  # voice_b
                    print(parts)
                    updated_line = ";".join([part.strip() for part in parts]) + "\n"
                    outfile.write(updated_line)
                else:
                    print(f"⚠️ Ligne ignorée (format inattendu): {line.strip()}")
                    import sys
                    sys.exit(1)

if __name__ == "__main__":
    update_lines_with_voice_fields(INPUT_FILE, OUTPUT_FILE)