// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: heartBeatResp.proto

#ifndef PROTOBUF_heartBeatResp_2eproto__INCLUDED
#define PROTOBUF_heartBeatResp_2eproto__INCLUDED

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
#include <google/protobuf/message_lite.h>
#include <google/protobuf/repeated_field.h>
#include <google/protobuf/extension_set.h>
// @@protoc_insertion_point(includes)

// Internal implementation detail -- do not call these.
void  protobuf_AddDesc_heartBeatResp_2eproto();
void protobuf_AssignDesc_heartBeatResp_2eproto();
void protobuf_ShutdownFile_heartBeatResp_2eproto();

class HeartBeatResp;

enum HeartBeatResp_Result {
  HeartBeatResp_Result_FAIL = -1,
  HeartBeatResp_Result_OK = 0
};
bool HeartBeatResp_Result_IsValid(int value);
const HeartBeatResp_Result HeartBeatResp_Result_Result_MIN = HeartBeatResp_Result_FAIL;
const HeartBeatResp_Result HeartBeatResp_Result_Result_MAX = HeartBeatResp_Result_OK;
const int HeartBeatResp_Result_Result_ARRAYSIZE = HeartBeatResp_Result_Result_MAX + 1;

// ===================================================================

class HeartBeatResp : public ::google::protobuf::MessageLite {
 public:
  HeartBeatResp();
  virtual ~HeartBeatResp();

  HeartBeatResp(const HeartBeatResp& from);

  inline HeartBeatResp& operator=(const HeartBeatResp& from) {
    CopyFrom(from);
    return *this;
  }

  static const HeartBeatResp& default_instance();

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  // Returns the internal default instance pointer. This function can
  // return NULL thus should not be used by the user. This is intended
  // for Protobuf internal code. Please use default_instance() declared
  // above instead.
  static inline const HeartBeatResp* internal_default_instance() {
    return default_instance_;
  }
  #endif

  void Swap(HeartBeatResp* other);

  // implements Message ----------------------------------------------

  HeartBeatResp* New() const;
  void CheckTypeAndMergeFrom(const ::google::protobuf::MessageLite& from);
  void CopyFrom(const HeartBeatResp& from);
  void MergeFrom(const HeartBeatResp& from);
  void Clear();
  bool IsInitialized() const;

  int ByteSize() const;
  bool MergePartialFromCodedStream(
      ::google::protobuf::io::CodedInputStream* input);
  void SerializeWithCachedSizes(
      ::google::protobuf::io::CodedOutputStream* output) const;
  int GetCachedSize() const { return _cached_size_; }
  private:
  void SharedCtor();
  void SharedDtor();
  void SetCachedSize(int size) const;
  public:

  ::std::string GetTypeName() const;

  // nested types ----------------------------------------------------

  typedef HeartBeatResp_Result Result;
  static const Result FAIL = HeartBeatResp_Result_FAIL;
  static const Result OK = HeartBeatResp_Result_OK;
  static inline bool Result_IsValid(int value) {
    return HeartBeatResp_Result_IsValid(value);
  }
  static const Result Result_MIN =
    HeartBeatResp_Result_Result_MIN;
  static const Result Result_MAX =
    HeartBeatResp_Result_Result_MAX;
  static const int Result_ARRAYSIZE =
    HeartBeatResp_Result_Result_ARRAYSIZE;

  // accessors -------------------------------------------------------

  // required .HeartBeatResp.Result result = 1;
  inline bool has_result() const;
  inline void clear_result();
  static const int kResultFieldNumber = 1;
  inline ::HeartBeatResp_Result result() const;
  inline void set_result(::HeartBeatResp_Result value);

  // optional int64 nowtime = 2;
  inline bool has_nowtime() const;
  inline void clear_nowtime();
  static const int kNowtimeFieldNumber = 2;
  inline ::google::protobuf::int64 nowtime() const;
  inline void set_nowtime(::google::protobuf::int64 value);

  // @@protoc_insertion_point(class_scope:HeartBeatResp)
 private:
  inline void set_has_result();
  inline void clear_has_result();
  inline void set_has_nowtime();
  inline void clear_has_nowtime();

  ::google::protobuf::int64 nowtime_;
  int result_;

  mutable int _cached_size_;
  ::google::protobuf::uint32 _has_bits_[(2 + 31) / 32];

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  friend void  protobuf_AddDesc_heartBeatResp_2eproto_impl();
  #else
  friend void  protobuf_AddDesc_heartBeatResp_2eproto();
  #endif
  friend void protobuf_AssignDesc_heartBeatResp_2eproto();
  friend void protobuf_ShutdownFile_heartBeatResp_2eproto();

  void InitAsDefaultInstance();
  static HeartBeatResp* default_instance_;
};
// ===================================================================


// ===================================================================

// HeartBeatResp

// required .HeartBeatResp.Result result = 1;
inline bool HeartBeatResp::has_result() const {
  return (_has_bits_[0] & 0x00000001u) != 0;
}
inline void HeartBeatResp::set_has_result() {
  _has_bits_[0] |= 0x00000001u;
}
inline void HeartBeatResp::clear_has_result() {
  _has_bits_[0] &= ~0x00000001u;
}
inline void HeartBeatResp::clear_result() {
  result_ = -1;
  clear_has_result();
}
inline ::HeartBeatResp_Result HeartBeatResp::result() const {
  return static_cast< ::HeartBeatResp_Result >(result_);
}
inline void HeartBeatResp::set_result(::HeartBeatResp_Result value) {
  assert(::HeartBeatResp_Result_IsValid(value));
  set_has_result();
  result_ = value;
}

// optional int64 nowtime = 2;
inline bool HeartBeatResp::has_nowtime() const {
  return (_has_bits_[0] & 0x00000002u) != 0;
}
inline void HeartBeatResp::set_has_nowtime() {
  _has_bits_[0] |= 0x00000002u;
}
inline void HeartBeatResp::clear_has_nowtime() {
  _has_bits_[0] &= ~0x00000002u;
}
inline void HeartBeatResp::clear_nowtime() {
  nowtime_ = GOOGLE_LONGLONG(0);
  clear_has_nowtime();
}
inline ::google::protobuf::int64 HeartBeatResp::nowtime() const {
  return nowtime_;
}
inline void HeartBeatResp::set_nowtime(::google::protobuf::int64 value) {
  set_has_nowtime();
  nowtime_ = value;
}


// @@protoc_insertion_point(namespace_scope)

// @@protoc_insertion_point(global_scope)

#endif  // PROTOBUF_heartBeatResp_2eproto__INCLUDED