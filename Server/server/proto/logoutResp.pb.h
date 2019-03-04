// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: logoutResp.proto

#ifndef PROTOBUF_logoutResp_2eproto__INCLUDED
#define PROTOBUF_logoutResp_2eproto__INCLUDED

#include <string>

#include <google/protobuf/stubs/common.h>

#if GOOGLE_PROTOBUF_VERSION < 2005000
#error This file was generated by a newer version of protoc which is
#error incompatible with your Protocol Buffer headers.  Please update
#error your headers.
#endif
#if 2005000 < GOOGLE_PROTOBUF_MIN_PROTOC_VERSION
#error This file was generated by an older version of protoc which is
#error incompatible with your Protocol Buffer headers.  Please
#error regenerate this file with a newer version of protoc.
#endif

#include <google/protobuf/generated_message_util.h>
#include <google/protobuf/message.h>
#include <google/protobuf/repeated_field.h>
#include <google/protobuf/extension_set.h>
#include <google/protobuf/generated_enum_reflection.h>
#include <google/protobuf/unknown_field_set.h>
// @@protoc_insertion_point(includes)

// Internal implementation detail -- do not call these.
void  protobuf_AddDesc_logoutResp_2eproto();
void protobuf_AssignDesc_logoutResp_2eproto();
void protobuf_ShutdownFile_logoutResp_2eproto();

class LogoutResp;

enum LogoutResp_Result {
  LogoutResp_Result_FAIL = -1,
  LogoutResp_Result_OK = 0
};
bool LogoutResp_Result_IsValid(int value);
const LogoutResp_Result LogoutResp_Result_Result_MIN = LogoutResp_Result_FAIL;
const LogoutResp_Result LogoutResp_Result_Result_MAX = LogoutResp_Result_OK;
const int LogoutResp_Result_Result_ARRAYSIZE = LogoutResp_Result_Result_MAX + 1;

const ::google::protobuf::EnumDescriptor* LogoutResp_Result_descriptor();
inline const ::std::string& LogoutResp_Result_Name(LogoutResp_Result value) {
  return ::google::protobuf::internal::NameOfEnum(
    LogoutResp_Result_descriptor(), value);
}
inline bool LogoutResp_Result_Parse(
    const ::std::string& name, LogoutResp_Result* value) {
  return ::google::protobuf::internal::ParseNamedEnum<LogoutResp_Result>(
    LogoutResp_Result_descriptor(), name, value);
}
// ===================================================================

class LogoutResp : public ::google::protobuf::Message {
 public:
  LogoutResp();
  virtual ~LogoutResp();

  LogoutResp(const LogoutResp& from);

  inline LogoutResp& operator=(const LogoutResp& from) {
    CopyFrom(from);
    return *this;
  }

  inline const ::google::protobuf::UnknownFieldSet& unknown_fields() const {
    return _unknown_fields_;
  }

  inline ::google::protobuf::UnknownFieldSet* mutable_unknown_fields() {
    return &_unknown_fields_;
  }

  static const ::google::protobuf::Descriptor* descriptor();
  static const LogoutResp& default_instance();

  void Swap(LogoutResp* other);

  // implements Message ----------------------------------------------

  LogoutResp* New() const;
  void CopyFrom(const ::google::protobuf::Message& from);
  void MergeFrom(const ::google::protobuf::Message& from);
  void CopyFrom(const LogoutResp& from);
  void MergeFrom(const LogoutResp& from);
  void Clear();
  bool IsInitialized() const;

  int ByteSize() const;
  bool MergePartialFromCodedStream(
      ::google::protobuf::io::CodedInputStream* input);
  void SerializeWithCachedSizes(
      ::google::protobuf::io::CodedOutputStream* output) const;
  ::google::protobuf::uint8* SerializeWithCachedSizesToArray(::google::protobuf::uint8* output) const;
  int GetCachedSize() const { return _cached_size_; }
  private:
  void SharedCtor();
  void SharedDtor();
  void SetCachedSize(int size) const;
  public:

  ::google::protobuf::Metadata GetMetadata() const;

  // nested types ----------------------------------------------------

  typedef LogoutResp_Result Result;
  static const Result FAIL = LogoutResp_Result_FAIL;
  static const Result OK = LogoutResp_Result_OK;
  static inline bool Result_IsValid(int value) {
    return LogoutResp_Result_IsValid(value);
  }
  static const Result Result_MIN =
    LogoutResp_Result_Result_MIN;
  static const Result Result_MAX =
    LogoutResp_Result_Result_MAX;
  static const int Result_ARRAYSIZE =
    LogoutResp_Result_Result_ARRAYSIZE;
  static inline const ::google::protobuf::EnumDescriptor*
  Result_descriptor() {
    return LogoutResp_Result_descriptor();
  }
  static inline const ::std::string& Result_Name(Result value) {
    return LogoutResp_Result_Name(value);
  }
  static inline bool Result_Parse(const ::std::string& name,
      Result* value) {
    return LogoutResp_Result_Parse(name, value);
  }

  // accessors -------------------------------------------------------

  // required .LogoutResp.Result result = 1;
  inline bool has_result() const;
  inline void clear_result();
  static const int kResultFieldNumber = 1;
  inline ::LogoutResp_Result result() const;
  inline void set_result(::LogoutResp_Result value);

  // @@protoc_insertion_point(class_scope:LogoutResp)
 private:
  inline void set_has_result();
  inline void clear_has_result();

  ::google::protobuf::UnknownFieldSet _unknown_fields_;

  int result_;

  mutable int _cached_size_;
  ::google::protobuf::uint32 _has_bits_[(1 + 31) / 32];

  friend void  protobuf_AddDesc_logoutResp_2eproto();
  friend void protobuf_AssignDesc_logoutResp_2eproto();
  friend void protobuf_ShutdownFile_logoutResp_2eproto();

  void InitAsDefaultInstance();
  static LogoutResp* default_instance_;
};
// ===================================================================


// ===================================================================

// LogoutResp

// required .LogoutResp.Result result = 1;
inline bool LogoutResp::has_result() const {
  return (_has_bits_[0] & 0x00000001u) != 0;
}
inline void LogoutResp::set_has_result() {
  _has_bits_[0] |= 0x00000001u;
}
inline void LogoutResp::clear_has_result() {
  _has_bits_[0] &= ~0x00000001u;
}
inline void LogoutResp::clear_result() {
  result_ = -1;
  clear_has_result();
}
inline ::LogoutResp_Result LogoutResp::result() const {
  return static_cast< ::LogoutResp_Result >(result_);
}
inline void LogoutResp::set_result(::LogoutResp_Result value) {
  assert(::LogoutResp_Result_IsValid(value));
  set_has_result();
  result_ = value;
}


// @@protoc_insertion_point(namespace_scope)

#ifndef SWIG
namespace google {
namespace protobuf {

template <>
inline const EnumDescriptor* GetEnumDescriptor< ::LogoutResp_Result>() {
  return ::LogoutResp_Result_descriptor();
}

}  // namespace google
}  // namespace protobuf
#endif  // SWIG

// @@protoc_insertion_point(global_scope)

#endif  // PROTOBUF_logoutResp_2eproto__INCLUDED
