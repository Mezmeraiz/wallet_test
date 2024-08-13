proto:
	@echo "* protobuf generation *"
	@flutter pub global activate protoc_plugin
	@protoc  -I=./proto --dart_out=./pb_output ./proto/**.proto
	@cp ./pb_output/* ../lib/protobuf