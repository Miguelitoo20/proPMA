import UIKit
import Firebase
import FirebaseDatabase

class AgregarPublicacionViewController: UIViewController {

    @IBOutlet weak var tituloTextField: UITextField!
    @IBOutlet weak var textoTextView: UITextView!
    
    var databaseRef: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRef = Database.database().reference()
    }
    
    @IBAction func guardarPublicacionTapped(_ sender: Any) {
        guard let user = Auth.auth().currentUser else { return }
        let usuario = user.email ?? "Usuario desconocido"
        let titulo = tituloTextField.text ?? ""
        let texto = textoTextView.text ?? ""

        let publicacionRef = databaseRef.child("publicaciones").childByAutoId()
        let publicacionData: [String: Any] = ["usuario": usuario, "titulo": titulo, "texto": texto]

        publicacionRef.setValue(publicacionData) { (error, ref) in
            if let error = error {
                print("Error al guardar la publicación: \(error)")
                return
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func volverTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
