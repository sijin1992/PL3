PB_FILE=$(shell ls *.proto)
PB_SOURCE=$(patsubst %.proto,%.pb.cc,$(PB_FILE))
PB_OBJ=$(patsubst %.proto,%.pb.o,$(PB_FILE))
PB_BIN=$(patsubst %.proto,%.pb,$(PB_FILE))
TARGET=$(PB_SOURCE) all_pb_bin libAllProto.a

all: cleanall
	cp proto/*.proto ./
	cp proto4server/*.proto ./
	make real

real:$(TARGET)

$(PB_BIN):%.pb:%.proto
	protoc --descriptor_set_out $@ $<

all_pb_bin:$(PB_BIN)
	mkdir -p ../lua/protobuf/
	rm -f ../lua/protobuf/*.pb
	cp *.pb ../lua/protobuf/

libAllProto.a:$(PB_OBJ)
	ar rcs $@ $^

$(PB_SOURCE):%.pb.cc: %.proto
	protoc --cpp_out=. $<

$(PB_OBJ):%.pb.o: %.pb.cc
	g++ -c $< `pkg-config --cflags protobuf` 

clean:
	rm -f $(PB_OBJ) libAllProto.a

cleanall:
	rm -f *.proto
	rm -f $(PB_OBJ) $(PB_BIN) $(patsubst %.proto,%.pb.cc,$(PB_FILE)) $(patsubst %.proto,%.pb.h,$(PB_FILE)) libAllProto.a