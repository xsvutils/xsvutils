
perl -MEncode -npe '
    s/(%5C|\\)/\\\\/gi;
    s/%([01][0-9A-F]|3B|7F)/"\\x".uc($1)/egi;
    s/%([2-9A-F][0-9A-F])/pack("H2",$1)/egi;
    $_ = encode("utf-8", decode("sjis", $_));
'
# %25 %
# %26 &
# %3B ;
# %3D =
# %5C \

