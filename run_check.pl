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

	if ($version == "master" or $version ge "1.3.0") {
		mkdir "build";
		chdir "build";
		system("cmake -DCMAKE_INSTALL_PREFIX=$root/$version -DENABLE_SCE=TRUE -DCMAKE_BUILD_TYPE=Debug ..");
		system("make");
		system("make install");
		chdir "..";
	}
	else {
		system("./configure --prefix $root/$version --enable-sce CFLAGS='-g -Og -fpermissive -w'; make install" );
	}

	chdir "..";
}

sub dump_abi {
	my $version = shift;
	my $libopenscap_path;

	if ($version == "master" or $version ge "1.3.0") {
		$libopenscap_path = "$version/lib64/libopenscap.so";
	} else {
		$libopenscap_path = "$version/lib/libopenscap.so";
	}
	system ("abi-dumper $libopenscap_path -public-headers $version/include/openscap -lver $version -o $version.dump");
}

download($old);
build($old);
dump_abi($old);

download($new);
build($new);
dump_abi($new);

system("pwd");
system("abi-compliance-checker -lib openscap -old $old.dump -new $new.dump");
system("cp compat_reports/openscap/${old}_to_${new}/compat_report.html reports/${old}_${new}.html") and die "Can't find compat_reports/openscap/${old}_to_${new}/compat_report.html";
system("firefox reports/${old}_${new}.html");
system("git add reports/${old}_${new}.html");
print "\nPlease commit and push the latest report to the repository\n";
