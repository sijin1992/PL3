// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: CmdSync.proto

#define INTERNAL_SUPPRESS_PROTOBUF_FIELD_DEPRECATION
#include "CmdSync.pb.h"

#include <algorithm>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/once.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/wire_format_lite_inl.h>
// @@protoc_insertion_point(includes)

void protobuf_ShutdownFile_CmdSync_2eproto() {
  delete UserSyncResp::default_instance_;
}

#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
void protobuf_AddDesc_CmdSync_2eproto_impl() {
  GOOGLE_PROTOBUF_VERIFY_VERSION;

#else
void protobuf_AddDesc_CmdSync_2eproto() {
  static bool already_here = false;
  if (already_here) return;
  already_here = true;
  GOOGLE_PROTOBUF_VERIFY_VERSION;

#endif
  ::protobuf_AddDesc_UserSync_2eproto();
  UserSyncResp::default_instance_ = new UserSyncResp();
  UserSyncResp::default_instance_->InitAsDefaultInstance();
  ::google::protobuf::internal::OnShutdown(&protobuf_ShutdownFile_CmdSync_2eproto);
}

#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
GOOGLE_PROTOBUF_DECLARE_ONCE(protobuf_AddDesc_CmdSync_2eproto_once_);
void protobuf_AddDesc_CmdSync_2eproto() {
  ::google::protobuf::::google::protobuf::GoogleOnceInit(&protobuf_AddDesc_CmdSync_2eproto_once_,
                 &protobuf_AddDesc_CmdSync_2eproto_impl);
}
#else
// Force AddDescriptors() to be called at static initialization time.
struct StaticDescriptorInitializer_CmdSync_2eproto {
  StaticDescriptorInitializer_CmdSync_2eproto() {
    protobuf_AddDesc_CmdSync_2eproto();
  }
} static_descriptor_initializer_CmdSync_2eproto_;
#endif

// ===================================================================

#ifndef _MSC_VER
const int UserSyncResp::kResultFieldNumber;
const int UserSyncResp::kUserSyncFieldNumber;
#endif  // !_MSC_VER

UserSyncResp::UserSyncResp()
  : ::google::protobuf::MessageLite() {
  SharedCtor();
}

void UserSyncResp::InitAsDefaultInstance() {
#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  user_sync_ = const_cast< ::UserSync*>(
      ::UserSync::internal_default_instance());
#else
  user_sync_ = const_cast< ::UserSync*>(&::UserSync::default_instance());
#endif
}

UserSyncResp::UserSyncResp(const UserSyncResp& from)
  : ::google::protobuf::MessageLite() {
  SharedCtor();
  MergeFrom(from);
}

void UserSyncResp::SharedCtor() {
  _cached_size_ = 0;
  result_ = 0;
  user_sync_ = NULL;
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

UserSyncResp::~UserSyncResp() {
  SharedDtor();
}

void UserSyncResp::SharedDtor() {
  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  if (this != &default_instance()) {
  #else
  if (this != default_instance_) {
  #endif
    delete user_sync_;
  }
}

void UserSyncResp::SetCachedSize(int size) const {
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
}
const UserSyncResp& UserSyncResp::default_instance() {
#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  protobuf_AddDesc_CmdSync_2eproto();
#else
  if (default_instance_ == NULL) protobuf_AddDesc_CmdSync_2eproto();
#endif
  return *default_instance_;
}

UserSyncResp* UserSyncResp::default_instance_ = NULL;

UserSyncResp* UserSyncResp::New() const {
  return new UserSyncResp;
}

void UserSyncResp::Clear() {
  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    result_ = 0;
    if (has_user_sync()) {
      if (user_sync_ != NULL) user_sync_->::UserSync::Clear();
    }
  }
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

bool UserSyncResp::MergePartialFromCodedStream(
    ::google::protobuf::io::CodedInputStream* input) {
#define DO_(EXPRESSION) if (!(EXPRESSION)) return false
  ::google::protobuf::uint32 tag;
  while ((tag = input->ReadTag()) != 0) {
    switch (::google::protobuf::internal::WireFormatLite::GetTagFieldNumber(tag)) {
      // required int32 result = 1;
      case 1: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &result_)));
          set_has_result();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(18)) goto parse_user_sync;
        break;
      }

      // optional .UserSync user_sync = 2;
      case 2: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_LENGTH_DELIMITED) {
         parse_user_sync:
          DO_(::google::protobuf::internal::WireFormatLite::ReadMessageNoVirtual(
               input, mutable_user_sync()));
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

void UserSyncResp::SerializeWithCachedSizes(
    ::google::protobuf::io::CodedOutputStream* output) const {
  // required int32 result = 1;
  if (has_result()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(1, this->result(), output);
  }

  // optional .UserSync user_sync = 2;
  if (has_user_sync()) {
    ::google::protobuf::internal::WireFormatLite::WriteMessage(
      2, this->user_sync(), output);
  }

}

int UserSyncResp::ByteSize() const {
  int total_size = 0;

  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    // required int32 result = 1;
    if (has_result()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->result());
    }

    // optional .UserSync user_sync = 2;
    if (has_user_sync()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::MessageSizeNoVirtual(
          this->user_sync());
    }

  }
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = total_size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
  return total_size;
}

void UserSyncResp::CheckTypeAndMergeFrom(
    const ::google::protobuf::MessageLite& from) {
  MergeFrom(*::google::protobuf::down_cast<const UserSyncResp*>(&from));
}

void UserSyncResp::MergeFrom(const UserSyncResp& from) {
  GOOGLE_CHECK_NE(&from, this);
  if (from._has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    if (from.has_result()) {
      set_result(from.result());
    }
    if (from.has_user_sync()) {
      mutable_user_sync()->::UserSync::MergeFrom(from.user_sync());
    }
  }
}

void UserSyncResp::CopyFrom(const UserSyncResp& from) {
  if (&from == this) return;
  Clear();
  MergeFrom(from);
}

bool UserSyncResp::IsInitialized() const {
  if ((_has_bits_[0] & 0x00000001) != 0x00000001) return false;

  if (has_user_sync()) {
    if (!this->user_sync().IsInitialized()) return false;
  }
  return true;
}

void UserSyncResp::Swap(UserSyncResp* other) {
  if (other != this) {
    std::swap(result_, other->result_);
    std::swap(user_sync_, other->user_sync_);
    std::swap(_has_bits_[0], other->_has_bits_[0]);
    std::swap(_cached_size_, other->_cached_size_);
  }
}

::std::string UserSyncResp::GetTypeName() const {
  return "UserSyncResp";
}


// @@protoc_insertion_point(namespace_scope)

// @@protoc_insertion_point(global_scope)
