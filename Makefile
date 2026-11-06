NASM ?= nasm
LD ?= ld
BUILD := build
TARGET := $(BUILD)/aether

.PHONY: all clean test install
all: $(TARGET)

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/aether.o: src/aether.asm | $(BUILD)
	$(NASM) -f elf64 -g -F dwarf $< -o $@

$(TARGET): $(BUILD)/aether.o
	$(LD) -o $@ $<

test: $(TARGET)
	bash tests/smoke.sh

install: $(TARGET)
	install -Dm755 $(TARGET) $(DESTDIR)/usr/local/bin/aether

clean:
	rm -rf $(BUILD)
