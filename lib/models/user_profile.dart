import 'package:hive/hive.dart';

@HiveType(typeId: 6)
class UserProfile extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String? photoUrl;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String? phone;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'phone': phone,
    };
  }

  static UserProfile fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      phone: map['phone'],
    );
  }
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 6;

  @override
  UserProfile read(BinaryReader reader) {
    return UserProfile(
      uid: reader.readString(),
      name: reader.readString(),
      email: reader.readString(),
      photoUrl: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      phone: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeString(obj.uid);
    writer.writeString(obj.name);
    writer.writeString(obj.email);
    writer.writeString(obj.photoUrl ?? '');
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeString(obj.phone ?? '');
  }
}
