// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: logprotocol.proto

#define INTERNAL_SUPPRESS_PROTOBUF_FIELD_DEPRECATION
#include "logprotocol.pb.h"

#include <algorithm>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/once.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/wire_format_lite_inl.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/generated_message_reflection.h>
#include <google/protobuf/reflection_ops.h>
#include <google/protobuf/wire_format.h>
// @@protoc_insertion_point(includes)

namespace {

const ::google::protobuf::Descriptor* LogReportReq_descriptor_ = NULL;
const ::google::protobuf::internal::GeneratedMessageReflection*
  LogReportReq_reflection_ = NULL;

}  // namespace


void protobuf_AssignDesc_logprotocol_2eproto() {
  protobuf_AddDesc_logprotocol_2eproto();
  const ::google::protobuf::FileDescriptor* file =
    ::google::protobuf::DescriptorPool::generated_pool()->FindFileByName(
      "logprotocol.proto");
  GOOGLE_CHECK(file != NULL);
  LogReportReq_descriptor_ = file->message_type(0);
  static const int LogReportReq_offsets_[10] = {
    GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET(LogReportReq, logid_),
    GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET(LogReportReq, logval1_),
    GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET(LogReportReq, logval2_),
    GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET(LogReportReq, logval3_),
    GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET(LogReportReq, logval4_),
    GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET(LogReportReq, logval5_),
    GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET(LogReportReq, logval6_),
    GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET(LogReportReq, logval7_),
    GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET(LogReportReq, logval8_),
    GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET(LogReportReq, logval9_),
  };
  LogReportReq_reflection_ =
    new ::google::protobuf::internal::GeneratedMessageReflection(
      LogReportReq_descriptor_,
      LogReportReq::default_instance_,
      LogReportReq_offsets_,
      GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET(LogReportReq, _has_bits_[0]),
      GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET(LogReportReq, _unknown_fields_),
      -1,
      ::google::protobuf::DescriptorPool::generated_pool(),
      ::google::protobuf::MessageFactory::generated_factory(),
      sizeof(LogReportReq));
}

namespace {

GOOGLE_PROTOBUF_DECLARE_ONCE(protobuf_AssignDescriptors_once_);
inline void protobuf_AssignDescriptorsOnce() {
  ::google::protobuf::GoogleOnceInit(&protobuf_AssignDescriptors_once_,
                 &protobuf_AssignDesc_logprotocol_2eproto);
}

void protobuf_RegisterTypes(const ::std::string&) {
  protobuf_AssignDescriptorsOnce();
  ::google::protobuf::MessageFactory::InternalRegisterGeneratedMessage(
    LogReportReq_descriptor_, &LogReportReq::default_instance());
}

}  // namespace

void protobuf_ShutdownFile_logprotocol_2eproto() {
  delete LogReportReq::default_instance_;
  delete LogReportReq_reflection_;
}

void protobuf_AddDesc_logprotocol_2eproto() {
  static bool already_here = false;
  if (already_here) return;
  already_here = true;
  GOOGLE_PROTOBUF_VERIFY_VERSION;

  ::google::protobuf::DescriptorPool::InternalAddGeneratedFile(
    "\n\021logprotocol.proto\"\266\001\n\014LogReportReq\022\r\n\005"
    "logid\030\001 \002(\005\022\017\n\007logval1\030\002 \001(\005\022\017\n\007logval2\030"
    "\003 \001(\005\022\017\n\007logval3\030\004 \001(\005\022\017\n\007logval4\030\005 \001(\005\022"
    "\017\n\007logval5\030\006 \001(\005\022\017\n\007logval6\030\007 \001(\005\022\017\n\007log"
    "val7\030\010 \001(\005\022\017\n\007logval8\030\t \001(\005\022\017\n\007logval9\030\n"
    " \001(\005", 204);
  ::google::protobuf::MessageFactory::InternalRegisterGeneratedFile(
    "logprotocol.proto", &protobuf_RegisterTypes);
  LogReportReq::default_instance_ = new LogReportReq();
  LogReportReq::default_instance_->InitAsDefaultInstance();
  ::google::protobuf::internal::OnShutdown(&protobuf_ShutdownFile_logprotocol_2eproto);
}

// Force AddDescriptors() to be called at static initialization time.
struct StaticDescriptorInitializer_logprotocol_2eproto {
  StaticDescriptorInitializer_logprotocol_2eproto() {
    protobuf_AddDesc_logprotocol_2eproto();
  }
} static_descriptor_initializer_logprotocol_2eproto_;

// ===================================================================

#ifndef _MSC_VER
const int LogReportReq::kLogidFieldNumber;
const int LogReportReq::kLogval1FieldNumber;
const int LogReportReq::kLogval2FieldNumber;
const int LogReportReq::kLogval3FieldNumber;
const int LogReportReq::kLogval4FieldNumber;
const int LogReportReq::kLogval5FieldNumber;
const int LogReportReq::kLogval6FieldNumber;
const int LogReportReq::kLogval7FieldNumber;
const int LogReportReq::kLogval8FieldNumber;
const int LogReportReq::kLogval9FieldNumber;
#endif  // !_MSC_VER

LogReportReq::LogReportReq()
  : ::google::protobuf::Message() {
  SharedCtor();
}

void LogReportReq::InitAsDefaultInstance() {
}

LogReportReq::LogReportReq(const LogReportReq& from)
  : ::google::protobuf::Message() {
  SharedCtor();
  MergeFrom(from);
}

void LogReportReq::SharedCtor() {
  _cached_size_ = 0;
  logid_ = 0;
  logval1_ = 0;
  logval2_ = 0;
  logval3_ = 0;
  logval4_ = 0;
  logval5_ = 0;
  logval6_ = 0;
  logval7_ = 0;
  logval8_ = 0;
  logval9_ = 0;
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

LogReportReq::~LogReportReq() {
  SharedDtor();
}

void LogReportReq::SharedDtor() {
  if (this != default_instance_) {
  }
}

void LogReportReq::SetCachedSize(int size) const {
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
}
const ::google::protobuf::Descriptor* LogReportReq::descriptor() {
  protobuf_AssignDescriptorsOnce();
  return LogReportReq_descriptor_;
}

const LogReportReq& LogReportReq::default_instance() {
  if (default_instance_ == NULL) protobuf_AddDesc_logprotocol_2eproto();
  return *default_instance_;
}

LogReportReq* LogReportReq::default_instance_ = NULL;

LogReportReq* LogReportReq::New() const {
  return new LogReportReq;
}

void LogReportReq::Clear() {
  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    logid_ = 0;
    logval1_ = 0;
    logval2_ = 0;
    logval3_ = 0;
    logval4_ = 0;
    logval5_ = 0;
    logval6_ = 0;
    logval7_ = 0;
  }
  if (_has_bits_[8 / 32] & (0xffu << (8 % 32))) {
    logval8_ = 0;
    logval9_ = 0;
  }
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
  mutable_unknown_fields()->Clear();
}

bool LogReportReq::MergePartialFromCodedStream(
    ::google::protobuf::io::CodedInputStream* input) {
#define DO_(EXPRESSION) if (!(EXPRESSION)) return false
  ::google::protobuf::uint32 tag;
  while ((tag = input->ReadTag()) != 0) {
    switch (::google::protobuf::internal::WireFormatLite::GetTagFieldNumber(tag)) {
      // required int32 logid = 1;
      case 1: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &logid_)));
          set_has_logid();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(16)) goto parse_logval1;
        break;
      }

      // optional int32 logval1 = 2;
      case 2: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_logval1:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &logval1_)));
          set_has_logval1();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(24)) goto parse_logval2;
        break;
      }

      // optional int32 logval2 = 3;
      case 3: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_logval2:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &logval2_)));
          set_has_logval2();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(32)) goto parse_logval3;
        break;
      }

      // optional int32 logval3 = 4;
      case 4: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_logval3:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &logval3_)));
          set_has_logval3();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(40)) goto parse_logval4;
        break;
      }

      // optional int32 logval4 = 5;
      case 5: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_logval4:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &logval4_)));
          set_has_logval4();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(48)) goto parse_logval5;
        break;
      }

      // optional int32 logval5 = 6;
      case 6: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_logval5:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &logval5_)));
          set_has_logval5();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(56)) goto parse_logval6;
        break;
      }

      // optional int32 logval6 = 7;
      case 7: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_logval6:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &logval6_)));
          set_has_logval6();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(64)) goto parse_logval7;
        break;
      }

      // optional int32 logval7 = 8;
      case 8: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_logval7:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &logval7_)));
          set_has_logval7();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(72)) goto parse_logval8;
        break;
      }

      // optional int32 logval8 = 9;
      case 9: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_logval8:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &logval8_)));
          set_has_logval8();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(80)) goto parse_logval9;
        break;
      }

      // optional int32 logval9 = 10;
      case 10: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_logval9:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &logval9_)));
          set_has_logval9();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectAtEnd()) return true;
        break;
      }

      default: {
      handle_uninterpreted:
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_END_GROUP) {
          return true;
        }
        DO_(::google::protobuf::internal::WireFormat::SkipField(
              input, tag, mutable_unknown_fields()));
        break;
      }
    }
  }
  return true;
#undef DO_
}

void LogReportReq::SerializeWithCachedSizes(
    ::google::protobuf::io::CodedOutputStream* output) const {
  // required int32 logid = 1;
  if (has_logid()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(1, this->logid(), output);
  }

  // optional int32 logval1 = 2;
  if (has_logval1()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(2, this->logval1(), output);
  }

  // optional int32 logval2 = 3;
  if (has_logval2()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(3, this->logval2(), output);
  }

  // optional int32 logval3 = 4;
  if (has_logval3()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(4, this->logval3(), output);
  }

  // optional int32 logval4 = 5;
  if (has_logval4()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(5, this->logval4(), output);
  }

  // optional int32 logval5 = 6;
  if (has_logval5()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(6, this->logval5(), output);
  }

  // optional int32 logval6 = 7;
  if (has_logval6()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(7, this->logval6(), output);
  }

  // optional int32 logval7 = 8;
  if (has_logval7()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(8, this->logval7(), output);
  }

  // optional int32 logval8 = 9;
  if (has_logval8()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(9, this->logval8(), output);
  }

  // optional int32 logval9 = 10;
  if (has_logval9()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(10, this->logval9(), output);
  }

  if (!unknown_fields().empty()) {
    ::google::protobuf::internal::WireFormat::SerializeUnknownFields(
        unknown_fields(), output);
  }
}

::google::protobuf::uint8* LogReportReq::SerializeWithCachedSizesToArray(
    ::google::protobuf::uint8* target) const {
  // required int32 logid = 1;
  if (has_logid()) {
    target = ::google::protobuf::internal::WireFormatLite::WriteInt32ToArray(1, this->logid(), target);
  }

  // optional int32 logval1 = 2;
  if (has_logval1()) {
    target = ::google::protobuf::internal::WireFormatLite::WriteInt32ToArray(2, this->logval1(), target);
  }

  // optional int32 logval2 = 3;
  if (has_logval2()) {
    target = ::google::protobuf::internal::WireFormatLite::WriteInt32ToArray(3, this->logval2(), target);
  }

  // optional int32 logval3 = 4;
  if (has_logval3()) {
    target = ::google::protobuf::internal::WireFormatLite::WriteInt32ToArray(4, this->logval3(), target);
  }

  // optional int32 logval4 = 5;
  if (has_logval4()) {
    target = ::google::protobuf::internal::WireFormatLite::WriteInt32ToArray(5, this->logval4(), target);
  }

  // optional int32 logval5 = 6;
  if (has_logval5()) {
    target = ::google::protobuf::internal::WireFormatLite::WriteInt32ToArray(6, this->logval5(), target);
  }

  // optional int32 logval6 = 7;
  if (has_logval6()) {
    target = ::google::protobuf::internal::WireFormatLite::WriteInt32ToArray(7, this->logval6(), target);
  }

  // optional int32 logval7 = 8;
  if (has_logval7()) {
    target = ::google::protobuf::internal::WireFormatLite::WriteInt32ToArray(8, this->logval7(), target);
  }

  // optional int32 logval8 = 9;
  if (has_logval8()) {
    target = ::google::protobuf::internal::WireFormatLite::WriteInt32ToArray(9, this->logval8(), target);
  }

  // optional int32 logval9 = 10;
  if (has_logval9()) {
    target = ::google::protobuf::internal::WireFormatLite::WriteInt32ToArray(10, this->logval9(), target);
  }

  if (!unknown_fields().empty()) {
    target = ::google::protobuf::internal::WireFormat::SerializeUnknownFieldsToArray(
        unknown_fields(), target);
  }
  return target;
}

int LogReportReq::ByteSize() const {
  int total_size = 0;

  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    // required int32 logid = 1;
    if (has_logid()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->logid());
    }

    // optional int32 logval1 = 2;
    if (has_logval1()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->logval1());
    }

    // optional int32 logval2 = 3;
    if (has_logval2()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->logval2());
    }

    // optional int32 logval3 = 4;
    if (has_logval3()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->logval3());
    }

    // optional int32 logval4 = 5;
    if (has_logval4()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->logval4());
    }

    // optional int32 logval5 = 6;
    if (has_logval5()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->logval5());
    }

    // optional int32 logval6 = 7;
    if (has_logval6()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->logval6());
    }

    // optional int32 logval7 = 8;
    if (has_logval7()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->logval7());
    }

  }
  if (_has_bits_[8 / 32] & (0xffu << (8 % 32))) {
    // optional int32 logval8 = 9;
    if (has_logval8()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->logval8());
    }

    // optional int32 logval9 = 10;
    if (has_logval9()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->logval9());
    }

  }
  if (!unknown_fields().empty()) {
    total_size +=
      ::google::protobuf::internal::WireFormat::ComputeUnknownFieldsSize(
        unknown_fields());
  }
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = total_size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
  return total_size;
}

void LogReportReq::MergeFrom(const ::google::protobuf::Message& from) {
  GOOGLE_CHECK_NE(&from, this);
  const LogReportReq* source =
    ::google::protobuf::internal::dynamic_cast_if_available<const LogReportReq*>(
      &from);
  if (source == NULL) {
    ::google::protobuf::internal::ReflectionOps::Merge(from, this);
  } else {
    MergeFrom(*source);
  }
}

void LogReportReq::MergeFrom(const LogReportReq& from) {
  GOOGLE_CHECK_NE(&from, this);
  if (from._has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    if (from.has_logid()) {
      set_logid(from.logid());
    }
    if (from.has_logval1()) {
      set_logval1(from.logval1());
    }
    if (from.has_logval2()) {
      set_logval2(from.logval2());
    }
    if (from.has_logval3()) {
      set_logval3(from.logval3());
    }
    if (from.has_logval4()) {
      set_logval4(from.logval4());
    }
    if (from.has_logval5()) {
      set_logval5(from.logval5());
    }
    if (from.has_logval6()) {
      set_logval6(from.logval6());
    }
    if (from.has_logval7()) {
      set_logval7(from.logval7());
    }
  }
  if (from._has_bits_[8 / 32] & (0xffu << (8 % 32))) {
    if (from.has_logval8()) {
      set_logval8(from.logval8());
    }
    if (from.has_logval9()) {
      set_logval9(from.logval9());
    }
  }
  mutable_unknown_fields()->MergeFrom(from.unknown_fields());
}

void LogReportReq::CopyFrom(const ::google::protobuf::Message& from) {
  if (&from == this) return;
  Clear();
  MergeFrom(from);
}

void LogReportReq::CopyFrom(const LogReportReq& from) {
  if (&from == this) return;
  Clear();
  MergeFrom(from);
}

bool LogReportReq::IsInitialized() const {
  if ((_has_bits_[0] & 0x00000001) != 0x00000001) return false;

  return true;
}

void LogReportReq::Swap(LogReportReq* other) {
  if (other != this) {
    std::swap(logid_, other->logid_);
    std::swap(logval1_, other->logval1_);
    std::swap(logval2_, other->logval2_);
    std::swap(logval3_, other->logval3_);
    std::swap(logval4_, other->logval4_);
    std::swap(logval5_, other->logval5_);
    std::swap(logval6_, other->logval6_);
    std::swap(logval7_, other->logval7_);
    std::swap(logval8_, other->logval8_);
    std::swap(logval9_, other->logval9_);
    std::swap(_has_bits_[0], other->_has_bits_[0]);
    _unknown_fields_.Swap(&other->_unknown_fields_);
    std::swap(_cached_size_, other->_cached_size_);
  }
}

::google::protobuf::Metadata LogReportReq::GetMetadata() const {
  protobuf_AssignDescriptorsOnce();
  ::google::protobuf::Metadata metadata;
  metadata.descriptor = LogReportReq_descriptor_;
  metadata.reflection = LogReportReq_reflection_;
  return metadata;
}


// @@protoc_insertion_point(namespace_scope)

// @@protoc_insertion_point(global_scope)
