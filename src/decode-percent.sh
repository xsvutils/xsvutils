
perl -nle '
    s/\+/ /g;
    s/%(2[0-46-9A-F]|3[A-F]|40|5[B-F]|60|7[B-E])/pack("H2",$1)/egi;
    s/%(C[2-9A-F]|D[0-9A-F])%([89AB][0-9A-F])/pack("H2",$1).pack("H2",$2)/egi;
    s/%(E[0-9A-F])%([89AB][0-9A-F])%([89AB][0-9A-F])/pack("H2",$1).pack("H2",$2).pack("H2",$3)/egi;
    s/%(F[0-7])%([89AB][0-9A-F])%([89AB][0-9A-F])%([89AB][0-9A-F])/pack("H2",$1).pack("H2",$2).pack("H2",$3).pack("H2",$4)/egi;
    s/;/%3B/g;
    print'

