# jent_web

Project Structure

features/
└── products/
    ├── data/
    │   ├── datasources/
    │   ├── models/
    │   ├── repositories/
    │   └── mappers/
    │
    ├── domain/
    │   ├── entities/
    │   ├── repositories/
    │   └── usecases/
    │
    └── presentation/
        ├── pages/
        ├── widgets/
        ├── providers/
        └── states/


Layers Page 

main.dart (kalau butuh add init firebase dan lain" disini) -> app.dart (disini untuk styling navigation)
base_page.dart (disini handling bottom sheet, prompt permission)
app.dart (ini inihirit base_page) -> route.page (handle navigationnya)
route.page -> loading.page -> mac_screen_home.page

menus :
readme.page : something like guide people when see the web
history.page : this previous app that i handled (use the marquee slide maybe?)
widget (instagram, linked, email, whatsapp) : just create like a wifi logo in mac, for the email maybe it can pop up the email form
card profile : just explain basic information about me
photo : just post the photo that i up to instagram
music : set a my daily playlist like pop song, poppunk song, metal, etc..
people notes : its like a comment from people that see the website

more : 
finder : where we can add some place that people can download my cv maybe


dock menu :
launch pad, email, notes, folder, music, photo