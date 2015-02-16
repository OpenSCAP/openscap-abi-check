#!/usr/bin/perl
#

my $old = $ARGV[0];
my $new = $ARGV[1];

my $root = `pwd`;
chomp($root);

sub download {
	my $version = shift;

	if ($version == "master" or $version =~ /^maint-\d/) {
		system("git clone --branch $version --single-branch https://github.com/OpenSCAP/openscap.git openscap-$version");
	}
	else {
		system("wget https://fedorahosted.org/releases/o/p/openscap/openscap-$version.tar.gz")
			and die "can't download https://fedorahosted.org/releases/o/p/openscap/openscap-$version.tar.gz";

		system("tar xfvz openscap-$version.tar.gz");
	}
}


sub build {
	my $version = shift;

	mkdir $version;
	chdir "openscap-$version";

	my $configure = `rpm --eval %configure`;
	chomp $configure;

	$configure =~ s/(\/usr|\/var|\/etc)/$root\/$version/g;
	if ($version == "master") {
		system("./autogen.sh");
	}
	system("$configure --enable-sce; make install" );

	chdir "..";
}

sub create_xml {
	my $version = shift;

	my $xml = "
<version>
    $version
</version>
<headers>
    $root/$version/include/openscap/
</headers>
<include_paths>
    $root/$version/include/openscap/
</include_paths>
<libs>
    $root/$version/lib64/
</libs>
";

	open my $f, ">", "$version.xml";
	print $f $xml;
	close(f);
}

download($old);
build($old);
create_xml($old);

download($new);
build($new);
create_xml($new);

system("abi-compliance-checker -cross-gcc /usr/bin/g++34 -lib openscap -old $old.xml -new $new.xml");
system("scp compat_reports/openscap/${old}_to_${new}/compat_report.html virtmaster\@sec-eng-01:public_html/${old}_${new}.html");
print "http://sec-eng-01.lab.eng.brq.redhat.com/virtmaster/${old}_${new}.html";
