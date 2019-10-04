implement kek;
# TODO: isolate compiled apps so they don't mess up the host
# maybe use ducker?

include "sys.m";
	sys: Sys;
stderr: ref Sys->FD;
include "bufio.m";

include "draw.m";
draw : Draw;

include "cache.m";
include "contents.m";
include "httpd.m";
	Private_info: import Httpd;

include "cgiparse.m";
cgiparse: CgiParse;
include "sh.m";

kek: module
{
    init: fn(g: ref Private_info, req: Httpd->Request);
};

init(g: ref Private_info, req: Httpd->Request)
{
	sys = load Sys Sys->PATH;
	stderr = sys->fildes(2);
	cgiparse = load CgiParse CgiParse->PATH;
	if( cgiparse == nil ) {
		sys->fprint( stderr, "kek: cannot load %s: %r\n", CgiParse->PATH);
		return;
	}


	send(g, cgiparse->cgiparse(g, req));
}

send(g: ref Private_info, cgidata: ref CgiData )
{
	bufio := g.bufio;
	Iobuf: import bufio;
	if( cgidata == nil ){
		g.bout.flush();
		return;
	}

	g.bout.puts( cgidata.httphd );

	g.bout.puts("<head><title>Echo</title>");
	g.bout.puts("<meta charset='utf-8'>");
	g.bout.puts("</head>");
	g.bout.puts("<body><h1>Kek!</h1>\r\n");
	g.bout.puts("<style>#code{ width:100%; height:100%; }</style>");
	g.bout.puts(sys->sprint("You requested a %s on %s",
	cgidata.method, cgidata.uri));

	code: string;
	if (cgidata.form != nil){
		g.bout.puts("</pre>");

		play := "/tmp/play";
		filename := play + ".b";
		fd: ref Sys->FD;

		while(cgidata.form!=nil){
			(tag, val) := hd cgidata.form;
			g.bout.puts(sys->sprint("<I>%s", "output: "));
			g.bout.puts("</I>");
			if (tag == "code"){
				fd = sys->create(filename, Sys->OWRITE, 8r666 );
				if(fd == nil)
					err(g, sys->sprint("cannot open %s: %r", filename));

				code = val;
				n := len code;
				if(sys->write(fd, array of byte code, n) != n)
					err(g, sys->sprint("error writing %s: %r", filename));

			}
			cgidata.form = tl cgidata.form;
		}

		disfile := play + ".dis";
		cmd := load Command "/dis/limbo.dis";
		cmd->init(nil, "limbo" :: "-o" :: disfile :: filename :: nil);

		# TODO: use a pipe instead
		if (0) {
            fds := array[2] of ref Sys->FD;
            if(sys->pipe(fds) < 0){
                err(g, sys->sprint("sh: can't make pipe: %r\n"));
            }
            fd0 := "/fd/" + sys->sprint("%d", fds[0].fd);
            err(g, "fd="+fd0);
            spawn run(disfile :: ">" :: fd0 :: nil);
		}

		out := play + ".out";
		sh := load Sh Sh->PATH;
		# see $home/dis/do
		err(g, sh->run(nil, "/dis/do" :: disfile :: out :: nil));
		fd = sys->open(out, Sys->OREAD);
		if(fd == nil)
			err(g, sys->sprint("cannot open %s: %r", out));


		buf := array[Sys->ATOMICIO] of byte;
		n := 0;
		if((n = sys->read(fd, buf, len buf)) > 0) {

		}

		g.bout.puts(string buf[0:n]);
		#fd := sys->fildes(0)
		#buf := array[Sys->ATOMICIO] of byte;
		#n := 0;
		#if((n = sys->read(fd, buf, len buf)) > 0) {

		#}

		g.bout.puts("</pre>\n");
	}
	if(code == nil) {
		fd := sys->open("/services/httpd/root/hello.b", Sys->OREAD);
		buf := array[Sys->ATOMICIO] of byte;
		n := 0;
		if((n = sys->read(fd, buf, len buf)) > 0) {

		}
		code = string buf[0:n];
	}


	g.bout.puts("<form action='kek' method='post'>");
	g.bout.puts("<input type='submit' value='Run'>");
	g.bout.puts("<textarea id='code' name='code'>");
	g.bout.puts(code);
	g.bout.puts("</textarea><br>");
	g.bout.puts("</form>");


	g.bout.puts("</body>\n");
	g.bout.flush();
}

run(argv: list of string)
{
	sh := load Sh Sh->PATH;
	sh->run(nil, argv);
}


err(g: ref Private_info, s: string)
{
	sys->fprint(sys->fildes(2), "kek: %s\n", s);
	if(g != nil) {
		bufio := g.bufio;
		Iobuf: import bufio;
		g.bout.puts(s);
	}
#	raise "fail:error";
}
