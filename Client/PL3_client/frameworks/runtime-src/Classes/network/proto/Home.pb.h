// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: Home.proto

#ifndef PROTOBUF_Home_2eproto__INCLUDED
#define PROTOBUF_Home_2eproto__INCLUDED

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
void  protobuf_AddDesc_Home_2eproto();
void protobuf_AssignDesc_Home_2eproto();
void protobuf_ShutdownFile_Home_2eproto();

class LandInfo;
class HomeSystemInfo;

// ===================================================================

class LandInfo : public ::google::protobuf::MessageLite {
 public:
  LandInfo();
  virtual ~LandInfo();

  LandInfo(const LandInfo& from);

  inline LandInfo& operator=(const LandInfo& from) {
    CopyFrom(from);
    return *this;
  }

  static const LandInfo& default_instance();

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  // Returns the internal default instance pointer. This function can
  // return NULL thus should not be used by the user. This is intended
  // for Protobuf internal code. Please use default_instance() declared
  // above instead.
  static inline const LandInfo* internal_default_instance() {
    return default_instance_;
  }
  #endif

  void Swap(LandInfo* other);

  // implements Message ----------------------------------------------

  LandInfo* New() const;
  void CheckTypeAndMergeFrom(const ::google::protobuf::MessageLite& from);
  void CopyFrom(const LandInfo& from);
  void MergeFrom(const LandInfo& from);
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

  // accessors -------------------------------------------------------

  // required int32 land_index = 1;
  inline bool has_land_index() const;
  inline void clear_land_index();
  static const int kLandIndexFieldNumber = 1;
  inline ::google::protobuf::int32 land_index() const;
  inline void set_land_index(::google::protobuf::int32 value);

  // optional int32 resource_type = 2;
  inline bool has_resource_type() const;
  inline void clear_resource_type();
  static const int kResourceTypeFieldNumber = 2;
  inline ::google::protobuf::int32 resource_type() const;
  inline void set_resource_type(::google::protobuf::int32 value);

  // optional int32 resource_level = 3;
  inline bool has_resource_level() const;
  inline void clear_resource_level();
  static const int kResourceLevelFieldNumber = 3;
  inline ::google::protobuf::int32 resource_level() const;
  inline void set_resource_level(::google::protobuf::int32 value);

  // optional int32 resource_status = 4;
  inline bool has_resource_status() const;
  inline void clear_resource_status();
  static const int kResourceStatusFieldNumber = 4;
  inline ::google::protobuf::int32 resource_status() const;
  inline void set_resource_status(::google::protobuf::int32 value);

  // optional int32 res_refresh_times = 5;
  inline bool has_res_refresh_times() const;
  inline void clear_res_refresh_times();
  static const int kResRefreshTimesFieldNumber = 5;
  inline ::google::protobuf::int32 res_refresh_times() const;
  inline void set_res_refresh_times(::google::protobuf::int32 value);

  // optional int32 resource_num = 6;
  inline bool has_resource_num() const;
  inline void clear_resource_num();
  static const int kResourceNumFieldNumber = 6;
  inline ::google::protobuf::int32 resource_num() const;
  inline void set_resource_num(::google::protobuf::int32 value);

  // optional bool helped = 7;
  inline bool has_helped() const;
  inline void clear_helped();
  static const int kHelpedFieldNumber = 7;
  inline bool helped() const;
  inline void set_helped(bool value);

  // @@protoc_insertion_point(class_scope:LandInfo)
 private:
  inline void set_has_land_index();
  inline void clear_has_land_index();
  inline void set_has_resource_type();
  inline void clear_has_resource_type();
  inline void set_has_resource_level();
  inline void clear_has_resource_level();
  inline void set_has_resource_status();
  inline void clear_has_resource_status();
  inline void set_has_res_refresh_times();
  inline void clear_has_res_refresh_times();
  inline void set_has_resource_num();
  inline void clear_has_resource_num();
  inline void set_has_helped();
  inline void clear_has_helped();

  ::google::protobuf::int32 land_index_;
  ::google::protobuf::int32 resource_type_;
  ::google::protobuf::int32 resource_level_;
  ::google::protobuf::int32 resource_status_;
  ::google::protobuf::int32 res_refresh_times_;
  ::google::protobuf::int32 resource_num_;
  bool helped_;

  mutable int _cached_size_;
  ::google::protobuf::uint32 _has_bits_[(7 + 31) / 32];

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  friend void  protobuf_AddDesc_Home_2eproto_impl();
  #else
  friend void  protobuf_AddDesc_Home_2eproto();
  #endif
  friend void protobuf_AssignDesc_Home_2eproto();
  friend void protobuf_ShutdownFile_Home_2eproto();

  void InitAsDefaultInstance();
  static LandInfo* default_instance_;
};
// -------------------------------------------------------------------

class HomeSystemInfo : public ::google::protobuf::MessageLite {
 public:
  HomeSystemInfo();
  virtual ~HomeSystemInfo();

  HomeSystemInfo(const HomeSystemInfo& from);

  inline HomeSystemInfo& operator=(const HomeSystemInfo& from) {
    CopyFrom(from);
    return *this;
  }

  static const HomeSystemInfo& default_instance();

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  // Returns the internal default instance pointer. This function can
  // return NULL thus should not be used by the user. This is intended
  // for Protobuf internal code. Please use default_instance() declared
  // above instead.
  static inline const HomeSystemInfo* internal_default_instance() {
    return default_instance_;
  }
  #endif

  void Swap(HomeSystemInfo* other);

  // implements Message ----------------------------------------------

  HomeSystemInfo* New() const;
  void CheckTypeAndMergeFrom(const ::google::protobuf::MessageLite& from);
  void CopyFrom(const HomeSystemInfo& from);
  void MergeFrom(const HomeSystemInfo& from);
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

  // accessors -------------------------------------------------------

  // optional int32 max_land_num = 1;
  inline bool has_max_land_num() const;
  inline void clear_max_land_num();
  static const int kMaxLandNumFieldNumber = 1;
  inline ::google::protobuf::int32 max_land_num() const;
  inline void set_max_land_num(::google::protobuf::int32 value);

  // repeated .LandInfo land_info = 2;
  inline int land_info_size() const;
  inline void clear_land_info();
  static const int kLandInfoFieldNumber = 2;
  inline const ::LandInfo& land_info(int index) const;
  inline ::LandInfo* mutable_land_info(int index);
  inline ::LandInfo* add_land_info();
  inline const ::google::protobuf::RepeatedPtrField< ::LandInfo >&
      land_info() const;
  inline ::google::protobuf::RepeatedPtrField< ::LandInfo >*
      mutable_land_info();

  // @@protoc_insertion_point(class_scope:HomeSystemInfo)
 private:
  inline void set_has_max_land_num();
  inline void clear_has_max_land_num();

  ::google::protobuf::RepeatedPtrField< ::LandInfo > land_info_;
  ::google::protobuf::int32 max_land_num_;

  mutable int _cached_size_;
  ::google::protobuf::uint32 _has_bits_[(2 + 31) / 32];

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  friend void  protobuf_AddDesc_Home_2eproto_impl();
  #else
  friend void  protobuf_AddDesc_Home_2eproto();
  #endif
  friend void protobuf_AssignDesc_Home_2eproto();
  friend void protobuf_ShutdownFile_Home_2eproto();

  void InitAsDefaultInstance();
  static HomeSystemInfo* default_instance_;
};
// ===================================================================


// ===================================================================

// LandInfo

// required int32 land_index = 1;
inline bool LandInfo::has_land_index() const {
  return (_has_bits_[0] & 0x00000001u) != 0;
}
inline void LandInfo::set_has_land_index() {
  _has_bits_[0] |= 0x00000001u;
}
inline void LandInfo::clear_has_land_index() {
  _has_bits_[0] &= ~0x00000001u;
}
inline void LandInfo::clear_land_index() {
  land_index_ = 0;
  clear_has_land_index();
}
inline ::google::protobuf::int32 LandInfo::land_index() const {
  return land_index_;
}
inline void LandInfo::set_land_index(::google::protobuf::int32 value) {
  set_has_land_index();
  land_index_ = value;
}

// optional int32 resource_type = 2;
inline bool LandInfo::has_resource_type() const {
  return (_has_bits_[0] & 0x00000002u) != 0;
}
inline void LandInfo::set_has_resource_type() {
  _has_bits_[0] |= 0x00000002u;
}
inline void LandInfo::clear_has_resource_type() {
  _has_bits_[0] &= ~0x00000002u;
}
inline void LandInfo::clear_resource_type() {
  resource_type_ = 0;
  clear_has_resource_type();
}
inline ::google::protobuf::int32 LandInfo::resource_type() const {
  return resource_type_;
}
inline void LandInfo::set_resource_type(::google::protobuf::int32 value) {
  set_has_resource_type();
  resource_type_ = value;
}

// optional int32 resource_level = 3;
inline bool LandInfo::has_resource_level() const {
  return (_has_bits_[0] & 0x00000004u) != 0;
}
inline void LandInfo::set_has_resource_level() {
  _has_bits_[0] |= 0x00000004u;
}
inline void LandInfo::clear_has_resource_level() {
  _has_bits_[0] &= ~0x00000004u;
}
inline void LandInfo::clear_resource_level() {
  resource_level_ = 0;
  clear_has_resource_level();
}
inline ::google::protobuf::int32 LandInfo::resource_level() const {
  return resource_level_;
}
inline void LandInfo::set_resource_level(::google::protobuf::int32 value) {
  set_has_resource_level();
  resource_level_ = value;
}

// optional int32 resource_status = 4;
inline bool LandInfo::has_resource_status() const {
  return (_has_bits_[0] & 0x00000008u) != 0;
}
inline void LandInfo::set_has_resource_status() {
  _has_bits_[0] |= 0x00000008u;
}
inline void LandInfo::clear_has_resource_status() {
  _has_bits_[0] &= ~0x00000008u;
}
inline void LandInfo::clear_resource_status() {
  resource_status_ = 0;
  clear_has_resource_status();
}
inline ::google::protobuf::int32 LandInfo::resource_status() const {
  return resource_status_;
}
inline void LandInfo::set_resource_status(::google::protobuf::int32 value) {
  set_has_resource_status();
  resource_status_ = value;
}

// optional int32 res_refresh_times = 5;
inline bool LandInfo::has_res_refresh_times() const {
  return (_has_bits_[0] & 0x00000010u) != 0;
}
inline void LandInfo::set_has_res_refresh_times() {
  _has_bits_[0] |= 0x00000010u;
}
inline void LandInfo::clear_has_res_refresh_times() {
  _has_bits_[0] &= ~0x00000010u;
}
inline void LandInfo::clear_res_refresh_times() {
  res_refresh_times_ = 0;
  clear_has_res_refresh_times();
}
inline ::google::protobuf::int32 LandInfo::res_refresh_times() const {
  return res_refresh_times_;
}
inline void LandInfo::set_res_refresh_times(::google::protobuf::int32 value) {
  set_has_res_refresh_times();
  res_refresh_times_ = value;
}

// optional int32 resource_num = 6;
inline bool LandInfo::has_resource_num() const {
  return (_has_bits_[0] & 0x00000020u) != 0;
}
inline void LandInfo::set_has_resource_num() {
  _has_bits_[0] |= 0x00000020u;
}
inline void LandInfo::clear_has_resource_num() {
  _has_bits_[0] &= ~0x00000020u;
}
inline void LandInfo::clear_resource_num() {
  resource_num_ = 0;
  clear_has_resource_num();
}
inline ::google::protobuf::int32 LandInfo::resource_num() const {
  return resource_num_;
}
inline void LandInfo::set_resource_num(::google::protobuf::int32 value) {
  set_has_resource_num();
  resource_num_ = value;
}

// optional bool helped = 7;
inline bool LandInfo::has_helped() const {
  return (_has_bits_[0] & 0x00000040u) != 0;
}
inline void LandInfo::set_has_helped() {
  _has_bits_[0] |= 0x00000040u;
}
inline void LandInfo::clear_has_helped() {
  _has_bits_[0] &= ~0x00000040u;
}
inline void LandInfo::clear_helped() {
  helped_ = false;
  clear_has_helped();
}
inline bool LandInfo::helped() const {
  return helped_;
}
inline void LandInfo::set_helped(bool value) {
  set_has_helped();
  helped_ = value;
}

// -------------------------------------------------------------------

// HomeSystemInfo

// optional int32 max_land_num = 1;
inline bool HomeSystemInfo::has_max_land_num() const {
  return (_has_bits_[0] & 0x00000001u) != 0;
}
inline void HomeSystemInfo::set_has_max_land_num() {
  _has_bits_[0] |= 0x00000001u;
}
inline void HomeSystemInfo::clear_has_max_land_num() {
  _has_bits_[0] &= ~0x00000001u;
}
inline void HomeSystemInfo::clear_max_land_num() {
  max_land_num_ = 0;
  clear_has_max_land_num();
}
inline ::google::protobuf::int32 HomeSystemInfo::max_land_num() const {
  return max_land_num_;
}
inline void HomeSystemInfo::set_max_land_num(::google::protobuf::int32 value) {
  set_has_max_land_num();
  max_land_num_ = value;
}

// repeated .LandInfo land_info = 2;
inline int HomeSystemInfo::land_info_size() const {
  return land_info_.size();
}
inline void HomeSystemInfo::clear_land_info() {
  land_info_.Clear();
}
inline const ::LandInfo& HomeSystemInfo::land_info(int index) const {
  return land_info_.Get(index);
}
inline ::LandInfo* HomeSystemInfo::mutable_land_info(int index) {
  return land_info_.Mutable(index);
}
inline ::LandInfo* HomeSystemInfo::add_land_info() {
  return land_info_.Add();
}
inline const ::google::protobuf::RepeatedPtrField< ::LandInfo >&
HomeSystemInfo::land_info() const {
  return land_info_;
}
inline ::google::protobuf::RepeatedPtrField< ::LandInfo >*
HomeSystemInfo::mutable_land_info() {
  return &land_info_;
}


// @@protoc_insertion_point(namespace_scope)

// @@protoc_insertion_point(global_scope)

#endif  // PROTOBUF_Home_2eproto__INCLUDED
