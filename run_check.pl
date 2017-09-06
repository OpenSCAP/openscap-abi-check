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
		system("wget -c https://github.com/OpenSCAP/openscap/releases/download/$version/openscap-$version.tar.gz")
			and die "can't download https://github.com/OpenSCAP/openscap/releases/download/$version/openscap-$version.tar.gz";

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
	system("./configure --prefix $root/$version --enable-sce CFLAGS='-g -Og -fpermissive -w'; make install" );

	chdir "..";
}

sub dump_abi {
	my $version = shift;

	system ("abi-dumper $version/lib/libopenscap.so -public-headers $version/include/openscap -lver $version -o $version.dump");
}

download($old);
build($old);
dump_abi($old);

download($new);
build($new);
dump_abi($new);

system("abi-compliance-checker -lib openscap -old $old.dump -new $new.dump");
system("cp compat_reports/openscap/${old}_to_${new}/compat_report.html reports/${old}_${new}.html");
system("firefox reports/${old}_${new}.html");
system("git add reports/${old}_${new}.html");
print "\nPlease commit and push the latest report to the repository\n";
