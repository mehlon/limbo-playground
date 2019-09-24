implement Ducker;

# Ducker is not docker.
# This is a port of ducker from Plan9 C to Inferno Limbo. 
# Ducker provides (by default) non-negotiable namespace sandboxing.

include "sys.m";
	sys: Sys;
	pctl, fprint, fildes, bind, open, sprint,
	FD, OREAD, ORDWR, NEWFD, FORKFD, NEWNS, 
	FORKNS, NODEVS, NEWENV, FORKENV, NEWPGRP: import sys;

include "draw.m";
include "arg.m";
include "newns.m";
include "sh.m";
include "string.m";

Ducker: module {
	init: fn(ctx: ref Draw->Context, argv: list of string);
};

debug:	int;
genns:	int;
nsf:		string;
rootf:	string;

# TODO - maybe use NEWNS rather than FORKNS using careful binds?
pctlflags:	int = NEWFD | FORKNS | NODEVS | NEWENV | NEWPGRP;

init(ctx: ref Draw->Context, argv: list of string) {
	sys = load Sys Sys->PATH;
	fprint, fildes: import sys;

	arg := load Arg Arg->PATH;
	usage, earg: import arg;
	if(arg == nil)
		raise "Could not load " + Arg->PATH;

	ns := load Newns Newns->PATH;
	if(ns == nil)
		raise "Could not load " + Newns->PATH;

	### Commandline arguments

	debug = 0;
	genns = 0;
	nsf = "";
	rootf = "";

	archf := "";
	protof := "";
	cfgf := "";
	user := readfile("/dev/user");

	cmd := "";
	cargs: list of string;

	arg->init(argv);
	arg->setusage("ducker [-Dg] [-p proto | -a arch] [-n namespace] [-r root] [-c cfg] [-u user] [cmd args…]");

	while((o := arg->opt()) != 0)
		case o {
		'g' =>	genns = 1;		# Generate the namespace(6) file and then parse
		'D' =>	debug = 1;
		'a' =>	archf = earg();
		'p' =>	protof = earg();
		'n' =>	nsf = earg();
		'r' =>		rootf = earg();
		'c' =>	cfgf = earg();
		'u' =>	user = earg();
		* =>		usage();
		}

	argv = arg->argv();
	argc := len argv;

	# If no cmd and no cfg, don't know what to run
	if(cfgf == nil && argc <= 0)
		usage();

	# Can't use both proto and arch
	if(protof != nil && archf != nil)
		usage();

	# Can't generate ns file and use an existing one
	if(nsf != nil && genns)
		usage();

	# Can't generate if we don't have someone to generate
	if(genns && archf == nil && protof == nil)
		usage();

	### Load all required data

	# Parse cfg, or expect argument for cmd -- argument takes precedence
	if(argc > 0) {
		cmd = hd argv;
		cargs = argv;
	} else if(cfgf != nil)
		parsecfg(cfgf);
	else
		usage();

	# Parse proto(6) file
	if(protof != nil)
		parseproto(protof);
	
	# Parse mkfs(8) arch file
	if(archf != nil)
		parsearch(archf);

	# Parse namespace(6) file
	if(nsf != nil) {
		err := ns->newns(user, nsf);
		if(err != nil)
			raise "err: newns(2) failed ­ " + err;
	}

	# Default rootf to /
	if((protof != nil || archf != nil) && rootf == nil)
		rootf = "/";

	# Change user using cap(3)
	#doas(user);

	### Run command

	if(debug) {
		fprint(fildes(2), "Argc = %d\nCmd = %s\n", argc, cmd);
		fprint(fildes(2), "Args:\n");
		for(a := argv; a != nil; a = tl a)
			fprint(fildes(2), "\t%s\n", hd a);
	}
	
	pidc := chan of int;
	
	spawn runcmd(ctx, cmd, argv, pidc);

	pid := <- pidc;

	if(debug)
		fprint(fildes(2), "Child pid = %d\n", pid);
}

# For use with spawn to run the desired command
runcmd(ctx: ref Draw->Context, cmd: string, argv: list of string, pidc: chan of int) {
	# TODO - fd list should be configurable
	 pidc <-= pctl(pctlflags, 0 :: 1 :: 2 :: nil);
	
	# You'll get a module not loaded at this point if it can't find the file
	c := load Command cmd;
	if(c == nil) {
		fprint(fildes(2), "err (child): file %s could not be loaded - %r\n", cmd);
		exit;
	}

	c->init(ctx, argv);
}

# Parse a mkfs(8) arch file
parsearch(fname: string) {
	fd := open(fname, OREAD);
	if(fd == nil)
		raise sprint("err: arch parse failed - could not open %s for read - %r", fname);

	# TODO - parse file and gen ns if need be
	
	raise "not impl";
}

# Parse proto(6) file
parseproto(fname: string) {
	fd := open(fname, OREAD);
	if(fd == nil)
		raise sprint("err: proto(6) parse failed - could not open %s for read - %r", fname);

	# TODO - parse file and gen ns if need be
	
	raise "not impl";
}

# Parse cfg attrdb(6) file
parsecfg(fname: string) {
	fd := open(fname, OREAD);
	if(fd == nil)
		raise sprint("err: attrdb(6) parse failed - could not open %s for read - %r", fname);

	# TODO - parse database and set environment variables
	
	raise "not impl";
}

# Use cap(3) to change to user -- stretch goal
doas(user: string) {
	fd := open("#¤", ORDWR);
	if(fd == nil)
		raise sprint("err: cap(3) failed - could not open #¤ for read - %r");

	# TODO - change to user using cap(3); need capability string and hash

	raise "not impl";
}

# Try to do a $path-style lookup for a shorthand command
# You're supposed to use sh.m, but that's a lot of infra
# $path = (/dis .)
lookup(cmd: string): string {
	# We can probably trust paths already possessing a leading /
	if(cmd[0] == '/')
		return cmd;

	# Trust a ./
	if(len cmd > 1) {
		pref := cmd[:2];
		if(pref == "./")
			return cmd;
	}

	sprint, OREAD: import sys;

	c := sprint("/dis/%s", cmd);
	if(tryopen(c))
		return c;

	c = sprint("./%s", cmd);
	if(tryopen(c))
		return c;

	# Try the same logic, but after appending .dis in case it was forgotten
	if(! contains(cmd, ".dis"))
		cmd = sprint("%s.dis", cmd);
	else
		return cmd;	# Give up

	c = sprint("/dis/%s", cmd);
	if(tryopen(c))
		return c;

	c = sprint("./%s", cmd);
	if(tryopen(c))
		return c;

	return cmd;
}

# Try to open helper for lookup()
tryopen(c: string): int {
	if(debug)
		sys->fprint(sys->fildes(2), "Trying: %s\n", c);

	fd := sys->open(c, sys->OREAD);
	if(fd != nil) {
		# Make sure it's not a directory - can't exec those ☺
		(err, dir) := sys->fstat(fd);
		if(err >= 0)
			if(! (dir.mode & Sys->DMDIR))
				return 1;
		# Maybe handle error?
	}

	return 0;
}

# Reads a (small) file into a string
readfile(f: string): string {
	fd := sys->open(f, sys->OREAD);
	if(fd == nil)
		return nil;

	buf := array[8192] of byte;
	n := sys->read(fd, buf, len buf);
	if(n < 0)
		return nil;

	return string buf[0:n];	
}

# Check whether a string s₀ contains another string s₁
contains(s₀, s₁: string ): int {
	s₀len := len s₀;
	s₁len := len s₁;

	if(s₁ == s₀)
		return 1;

	if(s₁len - s₀len < 0)
		return 0;

	# fooduckbar contains duck
	# dlen = 4
	# flen = 10
	# x₀ = 0
	# x₁ = 4
	# f[x₀:x₁]
	x₀ := 0;
	x₁ := s₁len;

	while(x₁ <= s₀len) {
		s := s₀[x₀:x₁];
		if(s == s₁)
			return 1;

		x₀++;
		x₁++;
	}

	return 0;
}
