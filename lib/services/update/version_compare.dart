// 语义化版本比较工具（纯函数，便于单元测试）
// 用于自动更新时比较 GitHub Release tag 与本地当前版本号

/// 剥离 `v`/`V` 前缀与 `+build`/`-prerelease` 元数据
///
/// - stripV('v0.0.2') => '0.0.2'
/// - stripV('v0.0.1+1') => '0.0.1'（剥 build 号）
/// - stripV('v0.0.2-beta.1') => '0.0.2'（剥预发布段）
String stripV(String version) {
  var v = version.trim();
  // 去掉可选的 v/V 前缀
  if (v.length > 1 && (v[0] == 'v' || v[0] == 'V') && v[1] != '.') {
    v = v.substring(1);
  }
  // 去掉 +build 元数据
  final plus = v.indexOf('+');
  if (plus > 0) v = v.substring(0, plus);
  // 去掉 -prerelease 元数据
  final dash = v.indexOf('-');
  if (dash > 0) v = v.substring(0, dash);
  return v;
}

/// 解析版本段为整数列表，非数字段视为 0（不抛异常）
List<int> _segments(String version) {
  final clean = stripV(version);
  if (clean.isEmpty) return const [0];
  return clean
      .split('.')
      .map((s) => int.tryParse(s.trim()) ?? 0)
      .toList();
}

/// 比较两个版本：a > b 返回 1，a == b 返回 0，a < b 返回 -1
///
/// 按点分段逐段数值比较（0.0.10 > 0.0.2，非字典序）；缺位补 0（0.1 == 0.1.0）；
/// 自动剥离 v 前缀与 +build/-prerelease 元数据。
int compareVersion(String a, String b) {
  final sa = _segments(a);
  final sb = _segments(b);
  final maxLen = sa.length > sb.length ? sa.length : sb.length;
  for (var i = 0; i < maxLen; i++) {
    final va = i < sa.length ? sa[i] : 0;
    final vb = i < sb.length ? sb[i] : 0;
    if (va > vb) return 1;
    if (va < vb) return -1;
  }
  return 0;
}

/// 是否有新版本：remote 版本高于 current
bool isNewer(String remote, String current) => compareVersion(remote, current) > 0;
