# 📶 GSM (2G) network with LimeSDR and Osmocom

> **⚠️ Warning:** Setting up a GSM network involves the utilization of specific
> frequencies that are generally heavily regulated. In most jurisdictions,
> transmitting on these frequencies without proper authorization is against the
> law and subject to severe penalties.
>
> Familiarize yourself with your local telecommunications laws and be aware of
> the legal and operational risks involved, including the possibility of
> causing interference with emergency services and public communications. You
> might want to explore the possibility of using Faraday cages or direct
> connections from the base station (SDR) to the mobile station (such as a
> smartphone) to avoid unauthorized use of the spectrum.
>
> The author and publisher of this guide explicitly reject any liability for
> illegal use or any adverse outcomes resulting from following this guide. The
> responsibility for any actions taken rests entirely with you.

This guide provides a straightforward method to set up a basic GSM network
using a [LimeSDR], software from the [Osmocom] project, and a Linux-based
computer.

GSM is the second generation (2G) digital cellular network technology which
mobile communications have once relied on. It has long been obsoleted due to
its limitations and well-documented security vulnerabilities, being replaced by
newer standards such as UMTS (3G), LTE (4G) and, more recently, 5G. Remarkably,
despite its obsolescense, even the most current smartphones remain compatible
with GSM, allowing them to connect to such networks without a hitch!

The setup outlined in this guide supports voice calls and SMS between the
network's subscribers and is capable of providing emergency alerts over
[CB (Cell Broadcast)]. It also provides internet access, although the slow
speeds of 2G technologies (GPRS and EDGE) render it impractical for using
modern websites and apps, as even loading a simple page can take long minutes.

It would be theoretically possible to enable calls to and from other carriers
by using the [OsmoSIPConnector], PBX software, and a compatible SIP service
provider. However, that is beyond the scope of this guide, as its focus is on
creating a minimalist, self-contained network.

The practical purpose for setting up a GSM network is up to you. It could serve
as an entertaining project or an educational tool and a means to explore the
evolution of mobile communication protocols, including their security
implications. These DIY GSM networks are sometimes showcased at hacker events
around the world as fun demonstrations, despite the questionable legality (see
the warning in the beginning of this guide).

[CB (Cell Broadcast)]: https://osmocom.org/projects/cellular-infrastructure/wiki/Cell_Broadcast
[LimeSDR]: https://limemicro.com/products/boards/limesdr/
[Osmocom]: https://osmocom.org/
[OsmoSIPConnector]: https://osmocom.org/projects/osmo-sip-conector

#### What about 3G and up?

The Osmocom project does support the UMTS standard; however, its
[documentation] suggests the need for a third-party hNodeB, a separate hardware
component. While the LimeSDR hardware is probably capable of handling the
protocol, I haven't been able to find documentation on anyone successfully
using it for that purpose. Online searches have led me to [OpenBTS-UMTS], a
now-discontinued project, making it challenging to find supporting resources.
Given these obstacles, and since 2G met my experimental needs, I have decided
not to pursue 3G.

For 4G and beyond, the [srsRAN] project is well-established, and provides
examples such as a setup [using a Raspberry Pi 4 and SDRs to create an eNodeB].
While I haven't experimented with this yet, it is certainly on my future
project list.

[documentation]: https://osmocom.org/projects/cellular-infrastructure/wiki/Osmocom_Network_In_The_Box
[OpenBTS-UMTS]: https://github.com/RangeNetworks/OpenBTS-UMTS
[srsRAN]: https://www.srslte.com/
[using a Raspberry Pi 4 and SDRs to create an eNodeB]: https://docs.srsran.com/projects/4g/en/next/app_notes/source/pi4/source/index.html

### Basic Concepts

- **MCC (Mobile Country Code):** a three-digit code assigned to each country,
  used to identify the country in which a mobile subscriber belongs.

- **MNC (Mobile Network Code):** a two or three-digit code used in combination
  with the MCC to identify a mobile phone operator within a country. Each
  operator has unique MNCs (often more than one), which, when paired with the
  MCC, forms an unique operator identification worldwide.

- **IMSI (International Mobile Subscriber Identity):** a unique identifier for
  each user of the network. It is stored on the SIM card, composed of up to 15
  digits, and structured to include the MCC, the MNC, and a unique subscriber
  number.

- **Ki:** a 128-bit value used in the authentication and ciphering process
   between the mobile device and the GSM network. It is stored both in the
   subscriber's SIM card and the network's database, and is used to
   authenticate the authorized users to the network.

> **ℹ️ Heads up:** you can find lists of MCC and MNC codes online, such as at
> [mcc-mnc.com].

[mcc-mnc.com]: https://mcc-mnc.com

### Setup

These setup instructions are tailored for a Debian 12 (“bookworm”) environment
with a LimeSDR connected via USB. Should your setup differ, adjustments to the
commands may be necessary.

#### Security considerations

#### Install required packages

First up, add the Osmocom project repository to your system. On Debian, the
simplest route to do so is by using [extrepo]. For other Linux flavors, refer
to the [Osmocom wiki].

```bash
apt install extrepo
extrepo enable osmocom-latest
```

Next, proceed to install the following packages.

```bash
apt install telnet         \
            limesuite      \
            osmo-hlr       \
            osmo-msc       \
            osmo-mgw       \
            osmo-stp       \
            osmo-bsc       \
            osmo-ggsn      \
            osmo-sgsn      \
            osmo-bts-trx   \
            osmo-trx-lms   \
            osmo-pcu       \
            osmo-cbc       \
            osmo-cbc-utils
```

If you haven't yet done so, you might want to take this opportunity to check
that your LimeSDR is connected, updated and working properly, by running
`LimeUtil --update` and `LimeQuickTest`.


[extrepo]: https://manpages.ubuntu.com/manpages/focal/man1/extrepo.1p.html
[Osmocom wiki]: https://osmocom.org/projects/cellular-infrastructure/wiki/Latest_Builds

#### Clone the repository

This repository contains the basic configuration files and auxiliary scripts
needed for our setup. Clone it using Git.

```bash
git clone git@github.com:miraliumre/gsm.git
```

#### Customize settings

Within the cloned repository, navigate to `etc/osmocom` for the relevant
Osmocom configuration files. Update these files based on your network
preferences.

**Start by editing [osmo-bsc.cfg].** Here, you'll find lines setting the MCC and
MNC for your network:

```
network country code 724
mobile network code 64
```

The default 724 is Brazil's country code, with 64 chosen to avoid conflicts
with existing Brazilian carriers' MNCs.

**In [osmo-ggsn.cfg],** you have the option to customize DNS and IP settings to
avoid conflicts with your existing networks.

```
ip dns 0 8.8.8.8
ip dns 1 8.8.4.4
ip prefix dynamic 172.16.32.0/24
```

**In [osmo-hlr.cfg],** note the following directives:

- `ussd route prefix *#100# internal own-msisdn` provides a USSD service to
  display the user's MSISDN by dialing `*#100#`.

- `ussd route prefix *#101# internal own-imsi` provides a USSD service for
  viewing the SIM card's IMSI by dialing `*#101#`.

- `subscriber-create-on-demand 8 cs+ps` enables auto-registering for devices
  attaching to the network. It declares that each device should be assigned an
  8-digit MSISDN, and be allowed to access both CS (Circuit Switched, e.g.
  voice calss) and PS (Packet Switched, e.g. internet access) services.

**Update [osmo-msc.cfg]** to reflect the network country code and mobile
network code from `osmo-bsc.cfg`. Here, you might also want to personalize the
short name and long name of your network. If you decide to require
authentication, change the `authentication optional` line to
`authentication required`.

```
network country code 724
mobile network code 64
short name Miralium
long name MiraliumResearch
authentication optional
```

**In [osmo-sgsn.cfg],** if you decide to require authentication on your
network, you might want to change the `auth-policy accept-all` line to
`auth-policy closed`.

**Finally,** copy all the configuration files to the `/etc/osmocom` directory on
your system. A script for doing so is provided under [src/update-cfg.sh] for
convenience.

[osmo-bsc.cfg]: etc/osmocom/osmo-bsc.cfg
[osmo-ggsn.cfg]: etc/osmocom/osmo-ggsn.cfg
[osmo-hlr.cfg]: etc/osmocom/osmo-hlr.cfg
[osmo-msc.cfg]: etc/osmocom/osmo-msc.cfg
[osmo-sgsn.cfg]: etc/osmocom/osmo-sgsn.cfg
[src/update-cfg.sh]: src/update-cfg.sh

#### Set up routing

As per our configuration, OsmoGGSN will use a TUN interface named `apn0` from which the GSM network subscribers will reach the internet. For it to work, you'll be required to:

1. create the TUN interface;
   ```bash
   ip tuntap add dev apn0 mode tun user root group root
   ```

2. add an IP address to the newly created interface (in accordance with the
   settings in `osmo-ggsn.cfg`); 
   ```bash
   ip addr add 192.168.7.1/24 dev apn0
   ```

3. bring the interface up;
   ```bash
   ip link set apn0 up
   ```

4. enable [IP forwarding] (e.g. by editing `/etc/sysctl.conf` to add the
   `net.ipv4.ip_forward = 1` line and loading the changes with `sysctl -p`);

5. configure iptables for NAT on the relevant network interfaces.
   ```bash
   iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
   iptables -t nat -A POSTROUTING -o apn0 -j MASQUERADE
   ```

On this last step, you'll be required to replace `eth0` with the name of the
network interface on your computer that is connected to the internet.

Remember that additional setup might be required to make these changes to
iptables persist across reboots. You may want to use the [iptables-persistent]
package.

> **ℹ️ Heads up:** manually setting iptables rules while [UFW] is installed and
> enable can cause conflicts. For this setup, it is recommended that you
> uninstall UFW and use iptables directly.

[IP forwarding]: https://openvpn.net/faq/what-is-and-how-do-i-enable-ip-forwarding-on-linux/
[iptables-persistent]: https://packages.debian.org/bookworm/iptables-persistent
[UFW]: https://help.ubuntu.com/community/UFW

#### Start the Osmocom services

Use the [src/update-cfg.sh] convenience script to start all the required
Osmocom services (i.e. by running `src/update-cfg.sh start`). If the services
had already been started previously, it is recommended to completely stop them
by running `src/update-cfg.sh stop` (and, possibly, `src/update-cfg.sh kill`,
if needed) before starting them again.

[src/update-cfg.sh]: src/update-cfg.sh

### Network Usage

#### Calls and SMS

#### Internet Access

#### Emergency Alerts

You can broadcast emergency alerts on the GSM network using the REST API
provided by OsmoCBC. The `osmo-cbc-utils` package provides a command line tool
named `cbc-apitool.py` to interact with said API.

For example, the following command sends an Extreme Alert message to the
network.

```bash
cbc-apitool.py create-cbs    \
               --msg-id 4371 \
               --payload-data-utf8 "Something has happened."
```

From my experience, transmitting these alerts and ensuring that they are
successfully received by the devices on the network can be somewhat tricky. As
such, it's advisable to familiarize yourself with the specifics of [CB]
technology.

Some issues you might run into:

- Devices might have emergency alert messages disabled, or in rare cases, may
  not support them at all.

- Messages that share the same ID and update number are treated as identical,
  regardless of any differences in their content. Therefore, if you create 
  message with a specific ID, delete it, and then try to issue a new message
  without altering the update number, devices that received the initial message
  might not display the subsequent one.

- Content length and character encoding issues may cause the alerts not to be
  displayed by the devices.

> **ℹ️ Heads up:** on Android, emergency alert settings are usually under
> *Settings* › *Notifications* › *Wireless emergency alerts*. On iOS, look for
> *Settings* › *Notifications* › *Government Alerts*.

[CB]: https://osmocom.org/projects/cellular-infrastructure/wiki/Cell_Broadcast

#### Subscriber Management

### Further Reading

### Acknowledgements

This guide builds upon the work of [Lucas Teske], who first delved into this
topic back in 2019, and later shared his insights at the [RF Village] at the
[H2HC] in 2022.

A huge shoutout is also due to the entire open source community that has created
and supports projects such as the LimeSDR and Osmocom. It is because of these
efforts that individual researchers and small business can now dive into complex
radio communication standards without shelling out massive amounts of cash for
high-end equipment typically reserved for the giants in the telecom industry.

[Lucas Teske]: https://lucasteske.dev/2019/12/creating-your-own-gsm-network-with-limesdr/
[RF Village]: https://github.com/racerxdl/h2hc-rfvillage
[H2HC]: https://www.h2hc.com.br/