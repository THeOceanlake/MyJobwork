/* 判断表是否存在 并删除 */
if  (select count(1) from Sysobjects where name in(UPPER('Tmp_zx#IP#')))=1
begin
	drop table TMP_ZX#IP#;
end