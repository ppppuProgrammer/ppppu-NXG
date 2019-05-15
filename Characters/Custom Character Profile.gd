extends CharacterProfile
class_name CustomCharacterProfile

# Hold off on this, figure out exactly how you want
# characters to work.
# Characters could just be a template that is applied and thus has no reason to have its properties
#changed.
# Any changes to the actor (on the character stage) would be handled by another resource/class.

func set_icon(new_icon:Texture):
	character_icon = new_icon

func set_name(new_name:String):
	character_name = new_name