// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: Building.proto

#define INTERNAL_SUPPRESS_PROTOBUF_FIELD_DEPRECATION
#include "Building.pb.h"

#include <algorithm>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/once.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/wire_format_lite_inl.h>
// @@protoc_insertion_point(includes)

void protobuf_ShutdownFile_Building_2eproto() {
  delete BuildingInfo::default_instance_;
}

#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
void protobuf_AddDesc_Building_2eproto_impl() {
  GOOGLE_PROTOBUF_VERIFY_VERSION;

#else
void protobuf_AddDesc_Building_2eproto() {
  static bool already_here = false;
  if (already_here) return;
  already_here = true;
  GOOGLE_PROTOBUF_VERIFY_VERSION;

#endif
  BuildingInfo::default_instance_ = new BuildingInfo();
  BuildingInfo::default_instance_->InitAsDefaultInstance();
  ::google::protobuf::internal::OnShutdown(&protobuf_ShutdownFile_Building_2eproto);
}

#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
GOOGLE_PROTOBUF_DECLARE_ONCE(protobuf_AddDesc_Building_2eproto_once_);
void protobuf_AddDesc_Building_2eproto() {
  ::google::protobuf::::google::protobuf::GoogleOnceInit(&protobuf_AddDesc_Building_2eproto_once_,
                 &protobuf_AddDesc_Building_2eproto_impl);
}
#else
// Force AddDescriptors() to be called at static initialization time.
struct StaticDescriptorInitializer_Building_2eproto {
  StaticDescriptorInitializer_Building_2eproto() {
    protobuf_AddDesc_Building_2eproto();
  }
} static_descriptor_initializer_Building_2eproto_;
#endif

// ===================================================================

#ifndef _MSC_VER
const int BuildingInfo::kLevelFieldNumber;
const int BuildingInfo::kUpgradeBeginTimeFieldNumber;
const int BuildingInfo::kHelpedFieldNumber;
const int BuildingInfo::kUpgradeExpFieldNumber;
#endif  // !_MSC_VER

BuildingInfo::BuildingInfo()
  : ::google::protobuf::MessageLite() {
  SharedCtor();
}

void BuildingInfo::InitAsDefaultInstance() {
}

BuildingInfo::BuildingInfo(const BuildingInfo& from)
  : ::google::protobuf::MessageLite() {
  SharedCtor();
  MergeFrom(from);
}

void BuildingInfo::SharedCtor() {
  _cached_size_ = 0;
  level_ = 0;
  upgrade_begin_time_ = 0;
  helped_ = false;
  upgrade_exp_ = 0;
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

BuildingInfo::~BuildingInfo() {
  SharedDtor();
}

void BuildingInfo::SharedDtor() {
  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  if (this != &default_instance()) {
  #else
  if (this != default_instance_) {
  #endif
  }
}

void BuildingInfo::SetCachedSize(int size) const {
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
}
const BuildingInfo& BuildingInfo::default_instance() {
#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  protobuf_AddDesc_Building_2eproto();
#else
  if (default_instance_ == NULL) protobuf_AddDesc_Building_2eproto();
#endif
  return *default_instance_;
}

BuildingInfo* BuildingInfo::default_instance_ = NULL;

BuildingInfo* BuildingInfo::New() const {
  return new BuildingInfo;
}

void BuildingInfo::Clear() {
  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    level_ = 0;
    upgrade_begin_time_ = 0;
    helped_ = false;
    upgrade_exp_ = 0;
  }
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

bool BuildingInfo::MergePartialFromCodedStream(
    ::google::protobuf::io::CodedInputStream* input) {
#define DO_(EXPRESSION) if (!(EXPRESSION)) return false
  ::google::protobuf::uint32 tag;
  while ((tag = input->ReadTag()) != 0) {
    switch (::google::protobuf::internal::WireFormatLite::GetTagFieldNumber(tag)) {
      // required int32 level = 1;
      case 1: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &level_)));
          set_has_level();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(16)) goto parse_upgrade_begin_time;
        break;
      }

      // optional int32 upgrade_begin_time = 2;
      case 2: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_upgrade_begin_time:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &upgrade_begin_time_)));
          set_has_upgrade_begin_time();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(24)) goto parse_helped;
        break;
      }

      // optional bool helped = 3;
      case 3: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_helped:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   bool, ::google::protobuf::internal::WireFormatLite::TYPE_BOOL>(
                 input, &helped_)));
          set_has_helped();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(32)) goto parse_upgrade_exp;
        break;
      }

      // optional int32 upgrade_exp = 4;
      case 4: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_upgrade_exp:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &upgrade_exp_)));
          set_has_upgrade_exp();
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
        DO_(::google::protobuf::internal::WireFormatLite::SkipField(input, tag));
        break;
      }
    }
  }
  return true;
#undef DO_
}

void BuildingInfo::SerializeWithCachedSizes(
    ::google::protobuf::io::CodedOutputStream* output) const {
  // required int32 level = 1;
  if (has_level()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(1, this->level(), output);
  }

  // optional int32 upgrade_begin_time = 2;
  if (has_upgrade_begin_time()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(2, this->upgrade_begin_time(), output);
  }

  // optional bool helped = 3;
  if (has_helped()) {
    ::google::protobuf::internal::WireFormatLite::WriteBool(3, this->helped(), output);
  }

  // optional int32 upgrade_exp = 4;
  if (has_upgrade_exp()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(4, this->upgrade_exp(), output);
  }

}

int BuildingInfo::ByteSize() const {
  int total_size = 0;

  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    // required int32 level = 1;
    if (has_level()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->level());
    }

    // optional int32 upgrade_begin_time = 2;
    if (has_upgrade_begin_time()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->upgrade_begin_time());
    }

    // optional bool helped = 3;
    if (has_helped()) {
      total_size += 1 + 1;
    }

    // optional int32 upgrade_exp = 4;
    if (has_upgrade_exp()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->upgrade_exp());
    }

  }
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = total_size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
  return total_size;
}

void BuildingInfo::CheckTypeAndMergeFrom(
    const ::google::protobuf::MessageLite& from) {
  MergeFrom(*::google::protobuf::down_cast<const BuildingInfo*>(&from));
}

void BuildingInfo::MergeFrom(const BuildingInfo& from) {
  GOOGLE_CHECK_NE(&from, this);
  if (from._has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    if (from.has_level()) {
      set_level(from.level());
    }
    if (from.has_upgrade_begin_time()) {
      set_upgrade_begin_time(from.upgrade_begin_time());
    }
    if (from.has_helped()) {
      set_helped(from.helped());
    }
    if (from.has_upgrade_exp()) {
      set_upgrade_exp(from.upgrade_exp());
    }
  }
}

void BuildingInfo::CopyFrom(const BuildingInfo& from) {
  if (&from == this) return;
  Clear();
  MergeFrom(from);
}

bool BuildingInfo::IsInitialized() const {
  if ((_has_bits_[0] & 0x00000001) != 0x00000001) return false;

  return true;
}

void BuildingInfo::Swap(BuildingInfo* other) {
  if (other != this) {
    std::swap(level_, other->level_);
    std::swap(upgrade_begin_time_, other->upgrade_begin_time_);
    std::swap(helped_, other->helped_);
    std::swap(upgrade_exp_, other->upgrade_exp_);
    std::swap(_has_bits_[0], other->_has_bits_[0]);
    std::swap(_cached_size_, other->_cached_size_);
  }
}

::std::string BuildingInfo::GetTypeName() const {
  return "BuildingInfo";
}


// @@protoc_insertion_point(namespace_scope)

// @@protoc_insertion_point(global_scope)