import 'package:googleapis_auth/auth_io.dart';

class GetServerKey {
  Future<String> getServerKeyToken() async {
    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];
    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": "fypconnect-19dfd",
        "private_key_id": "438aa1796920a8b8f5f1a1c786dc794eae18d065",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC+F5YlnbSShbbh\n6rIgfsv/84qmbfSEx3MLK18sXEhNnT0luh8bgTfpJ5oBxHX6BJfs9u0RZo0oexk2\nsRaHby5FuRJhIMBRkvXSWpudMELHcmctn8erBKvNV9OxcWAL+VKqOi953OXCxeZ4\nXrgrA6DBouLhhWoKdnYmURt/c9NAlQmCH64OWTf8rRy9XkPmO0+28eX2uBsMUVGv\nLGcM1CVCBahMPhrl7W0G4ON6ulVWPq7/nKjTMiAcx8JIsWGVWRr03ZkH0Haq6LMP\ngbbQfI6zVNNZhlaFGTOIBpfuGg7WeyzzUdW53eN0VXuAxKgCPlnmb4dfC94rIqxT\nkujOLLqVAgMBAAECggEACVCnk21QeXOi/BwfoXcFMSQykahGuLD7Yrs73TUid+cy\nJWSi/JqO7lZ59gc2Dsvl0/9fq6AeX7L0j9kKtRVOK61/iJHtyrGMaUP2ZzQDublR\n9Arl4mwGrTfWEFZxcfTER8I1LGAWRD6lZhWiKb1yRbrhKlL62MtoS8VitxKqcfol\n9D6KuouCqADAtV64GdGrMtzVtEFBtkbeW4XFHG71zR7Z9v2zR+ABnXd0FNWnOz/o\nUyjGaIBHg0vo3wrfRzhDSUs5/DrMaCfZSvG4mNBKKx33qlNXS9yxWrxElsRNO7Fj\nhKUm4Gco963h3vQx3RWF7+6GRs/Kn8IlL88EVRDRmwKBgQDzwv793Uyi5+TsagKg\nYv1dzUivPVMgce2olMnHpoIXPVD4f4JFnNCPh/HTYjrCxt3dI3a4s+9NPTT15yo7\nooogzcQ6XG7Bu5OcHR9MxE8GKneQJDA8kTFTxxKrPpSyNee6C2jhSWp3lcEB9TAa\nUwJGNJ7imThufQUN8qdGEO3WOwKBgQDHosozg0EtX3Ditvc96iumOOTBI7xEkxbO\nVoTZVdBr/oQN/mwEq1Y4Sq0YmiI5Ank0x3Re5uN8N/tef+tSlKneugzK7IZdNrw+\nOOPTbRQlYOCMUnibjP8X4LV7pinPkxg8GaM+XoMs1DB4XNK0Zy7DWNFiYmrv2wNH\nGJBuo84VbwKBgQCASaCfhKc/mSGe1o/5Tv+fLVnSeEjWa38zWNL1EwmmJ2wEzD6I\nWmZdE6POpwTb24OKTY6+2FvZ35uOyxEr/3gImaJrQJg9t3WRFLaTVUFtsk3oe1Mz\nnQpD2CJYI4BoZfxFqpmQ721r8FF6sUqWoBczUaBJC3BqnbtaQtmMA37YXwKBgQCK\nb4KT8iLSWeqn7ITKtIYMQEuw+xzk2LLp5uk85Nsg6F+ebJ1vJ3kkk/QwqUGuEt8G\nEIHMBYQecZuoTkBbBag+QPn6BcavAPPMmhqyVGOx/9n2tIHaLA4A+tweoH1B6hjW\nJFklONjxzzrFXGjonNy6re6UsPbC2TcOqCQP9RtFlQKBgE8JZOaMMeREuZahAYO7\n9yEwHdvkKjk0UcLPt9NzSIr4BGiLPnSRI1rAM9fBUOHrb+uL13n5OztDx1mVyuU2\nnSGXELURqwHmJaS5aYKQBpl7sB1QwtXv8HXUBSbhPrcPrtegTIo+urALq/3TtdXh\nnXqfdzY+caBZUzSF8qzlRFqG\n-----END PRIVATE KEY-----\n",
        "client_email":
            "firebase-adminsdk-fbsvc@fypconnect-19dfd.iam.gserviceaccount.com",
        "client_id": "116422226014810914174",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40fypconnect-19dfd.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com",
      }),
      scopes,
    );
    final accessServerKey = client.credentials.accessToken.data;

    return accessServerKey;
  }
}
