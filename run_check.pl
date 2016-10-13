#!/usr/bin/perl
#

my $old = $ARGV[0];
my $new = $ARGV[1];

my $root = `pwd`;
chomp($root);

sub download {
	my $version = shift;

	if ($version == "master" or $version =~ /^maint-\d/) {
		system("rm -r openscap-$version");
		system("git clone --branch $version --single-branch https://github.com/OpenSCAP/openscap.git openscap-$version");
	}
	else {
		system("wget -c https://fedorahosted.org/releases/o/p/openscap/openscap-$version.tar.gz")
			and die "can't download https://fedorahosted.org/releases/o/p/openscap/openscap-$version.tar.gz";

		system("tar xfvz openscap-$version.tar.gz");
	}
}


sub build {
	my $version = shift;

	mkdir $version;
	chdir "openscap-$version";

	if ($version == "master") {
		system("./autogen.sh");
	}
	system("./configure --prefix $root/$version --enable-sce; make install" );

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
system("cp compat_reports/openscap/${old}_to_${new}/compat_report.html reports/${old}_${new}.html");
system("firefox reports/${old}_${new}.html");
system("git add reports/${old}_${new}.html");
print "\nPlease commit and push the latest report to the repository\n";
