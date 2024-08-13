.PHONY: gen ffi_gen	proto

gen:
	@echo "* Running build runner *"
	@dart run build_runner build --delete-conflicting-outputs

ffi_gen:
	@echo "* ffi generation *"
	@dart run ffigen

proto:
	@echo "* protobuf generation *"
	@flutter pub global activate protoc_plugin
	@protoc  -I=./gen/proto --dart_out=./gen/pb_output ./gen/proto/**.proto
	@cp ./gen/pb_output/* ./lib/protobuf