class Siswa {
  final int idSiswa;
  final String nama;
  final String nis;
  final String username;
  final String
  password; // ⚠️ Hati-hati, ini hanya untuk demo. Di production, password harus dihash!

  Siswa({
    required this.idSiswa,
    required this.nama,
    required this.nis,
    required this.username,
    required this.password,
  });

  factory Siswa.fromJson(Map<String, dynamic> json) {
    return Siswa(
      idSiswa: json['id_siswa'] as int,
      nama: json['nama'] as String,
      nis: json['nis'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_siswa': idSiswa,
      'nama': nama,
      'nis': nis,
      'username': username,
      'password': password,
    };
  }
}
