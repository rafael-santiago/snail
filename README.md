# Snail

Sometimes you need to carry your house on your shoulders in order to call any place home. Deploying
a binary package instead of the code to be built. Talking about ``Unix``, be aware: it can be painful
in some cases.

There are a bunch of reasons for not doing it but even with all disadvantages if this snail attitude
is profitable to you... You should use this ``script``.

Firstly is necessary adapt your ``build``:

    - Adjusting the ``-rpath`` from your binaries to some specific path that you need to create in target machine;
    - Adjusting ``INTERP`` (dynamic loader path) to some specific path that you need to create in target machine;

A good choice is let ``-rpath` and ``INTERP`` path as the same.

After in your **build environment**, place all binaries which compose your binary package in some specific place ``X``, and
run ``snail.sh`` in this way:

        ``./snail.sh --directory=X --output=MyDependencies.zip``

At this point, ``snail.sh`` will scans the current environment in order to find and collect all dependency that
your package has. Producing at the end a ``zip`` file which gathers these dependencies.

Now, all you need to do is ``unzip`` these dependencies inside the directory ``X`` on **target machine**.

That's all folks, now you may say "home sweet home".

