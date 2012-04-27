# Hosted Marlin Service - Net TV Example

This is an example application for the Net TV plataform showcasing how to download or stream [Marlin DRM][marlin] videos with [Hosted Marlin Service][hms].

This example _is not_ a fully function video webstore (e.g. it doesn't manage users properly nor provides a pretty user interface), it is just a barebone implementation to test Marlin DRM content on a Net TV that you may hack around to integrate in your app. Notice also that the example was tested with a specific Philips Net TV device, so thorough Net TV compliance is absolutely not guaranteed; pull requests and issues are more than welcome of course :)

The server-side of the application (the "webstore", in Marlin-terms) is coded in Ruby using [Sinatra](sinatra), but it should not be necessary to have prevous experience with Ruby nor Sinatra to get it running or to understand what the code does, as it's very simple and quite thoroughly commented.

This example was made following [this tutorial](hms-tutorial).

You can see the example working at <http://marlin-nettv-example.heroku.com/> (note that you should visit this link with a Net TV device).

## Install & Run

### Git clone and install dependencies

This is the typical Ruby-project installation. If you don't have Ruby, I'd recommend installing it with [RVM][rvm].

    # Clone the repo and cd into it.
    # Install bundler if you haven't already:
    gem install bundler
    # Install all the project dependencies:
    bundle install

To get the server running you can then do:

    rackup

... and you will an instance of the application running at <http://localhost:9292>. Any change on the code of the application should be seen immediately without the need for restarting the server.

### Configure Hosted Marlin Service credentials

To run the application you will need to register in [HMS][hms]. Do so, and once you are logged in go to the home page and copy the code shown under Customer Authenticator Code into the `config.yml` file. Your `config.yml` should look something like:

    customer_authenticator: 123,6f5902ac237024bdd0c176cb93063dc4
    hms_hostname: ms3-gen.service.hostedmarlin.com

If you have a different HMS provider than hostedmarlin.com, you might change that as well.

To verify that your HMS credentials work properly, you can visit <http://localhost:9292/register> and see if it returns an XML file (this is a Marlin Bradband Registration transaction token).

### Package some content.

This is step is not necessary to get the application running, as it already comes with a couple of very short sample videos taken from the awesome [Sintel](sintel) and [Elephants Dream](elephants-dream) movies.

To encrypt an MP4 video you should use the `mp4dcfpackager` command as described [here](hms-packaging-content). For example:

    mp4dcfpackager --method CBC --content-type video/mp4 --content-id urn:marlin:organization:yourorganization:big-buck-bunny --key f7782e51dd43bac40861a4075647e874:00000000000000000000000000000000 big-buck-bunny.mp4 contents/big-buck-bunny.dcf

Then you must also create a `contents/big-buck-bunny.yml` [YAML](yaml) file, which shoud specify the key used to encript the file so the application can then use it to acquire Marlin Broadband License tokens. The file should look something like this:

    ---
    :key: f7782e51dd43bac40861a4075647e874

You can use the script included in this repository called `encrypt-content` to generate both the `.dcf` and `.yml` files. Notice that the script will require you to have the command `mp4dcfpackager` in your PATH:

    export PATH="$PATH:path/to/hms-tools"
    ./encrypt-content big-buck-bunny.mp4

You can also pass `--key` and `--id` parameters to the script.

The `.yml` for the content needs to have its cryptographic key, but it can also have the optional fields:

 - `id`: HMS ID. By default the application will use `urn:marlin:organization:example:<filename without extension>`
 - `title`: Content title. Default is the filename without extension.
 - `synopsis`: Default is `title`
 - `url`: The URL where the `.dcf` file is at. By default is `<your app instance base URL>/contents/<filenam without extension>.dcf`

[marlin]: http://en.wikipedia.org/wiki/Marlin_(DRM)
[hms]: https://www.hostedmarlin.com/
[sinatra]: http://www.sinatrarb.com
[rvm]: https://rvm.io
[sintel]: http://www.sintel.org/
[elephants-dream]: http://www.elephantsdream.org/
[hms-tutorial]: https://www.hostedmarlin.com/tutorial/
[hms-packaging-content]: https://www.hostedmarlin.com/tutorial/packaging_dcf.html
[yaml]: http://en.wikipedia.org/wiki/YAML